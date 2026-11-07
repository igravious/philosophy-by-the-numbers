require "test_helper"
require "minitest/mock"
require "tmpdir"
require "zlib"
require "stringio"
require "shellwords"

class FyleProcessingTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir("fyle-processing-")
    @counter = 0
    @fyle = Fyle.create!(what: "Philosophy Text", URL: "https://example.test/text")
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "binary files round trip arbitrary bytes without conversion" do
    path = File.join(@directory, "binary")
    bytes = "\x00\x92\xff".b
    assert_equal 3, @fyle.write_binary(path, bytes)
    assert_equal bytes, @fyle.read_binary(path)
  end

  test "plain text strips cached search engine markup and reuses materialized files" do
    cache("<BASE HREF=\"http://example.test\"><table>cached</table><hr>Text: λόγος", Fyle::PLAIN_TEXT, "UTF-8")
    with_output_paths do
      path, text = @fyle.materialize
      assert_equal "Text: λόγος", text
      assert_equal text.b, File.binread(path)
      assert_equal path, @fyle.reload.local_file
      assert_equal text, @fyle.materialize.last
      assert_equal text, @fyle.snarf
    end
  end

  test "Windows smart quotes repair a mislabeled UTF-8 source" do
    cache("Plato\x92s text".b, Fyle::PLAIN_TEXT, "UTF-8")
    with_output_paths do
      assert_equal "Plato’s text", @fyle.materialize.last.encode("UTF-8")
    end
    assert_equal "Windows-1252", @fyle.reload.encoding
  end

  test "invalid source and modified local encodings are rejected" do
    cache("\xff".b, Fyle::PLAIN_TEXT, "UTF-8")
    assert_equal "Invalid encoding!", assert_raises(RuntimeError) { @fyle.materialize }.message
    @fyle.update!(local_file: @fyle.cache_file)
    assert_equal "File changed on disk badly?", assert_raises(RuntimeError) { @fyle.materialize }.message
  end

  test "HTML materialization extracts body text and removes analytics scripts" do
    cache("<html><body><p>Ethics</p><script>var _gaq = []; (function() { tracking(); })();</script></body></html>", Fyle::HTML_TEXT, nil)
    with_output_paths do
      assert_equal "Ethics", @fyle.materialize.last.strip
    end
    assert_equal "UTF-8", @fyle.reload.encoding
  end

  test "TEI materialization extracts body text and normalizes its encoding" do
    [nil, "UTF-8"].each do |encoding|
      cache("<?xml version=\"1.0\" encoding=\"UTF-8\"?><TEI><text><body><p>λόγος</p></body></text></TEI>", Fyle::XML_TEI_TEXT, encoding)
      with_output_paths { assert_equal "λόγος", @fyle.materialize.last }
      assert_equal "UTF-8", @fyle.reload.encoding
    end
  end

  test "invalid TEI input cannot be relabeled as UTF-8" do
    cache("\xff".b, Fyle::XML_TEI_TEXT, nil)
    assert_includes assert_raises(RuntimeError) { @fyle.materialize }.message, "UTF-8"
  end

  test "parser output with invalid or unexpected encoding cannot be persisted" do
    document = Object.new
    invalid = "\xff".b.force_encoding("UTF-8")
    document.define_singleton_method(:xpath) { |_| Struct.new(:text).new(invalid) }
    cache("<html><body>text</body></html>", Fyle::HTML_TEXT, "ASCII-8BIT")
    Nokogiri.stub(:HTML, document) do
      assert_includes assert_raises(RuntimeError) { @fyle.materialize }.message, "unfair"
    end
    document.define_singleton_method(:xpath) { |_| Struct.new(:text).new("binary".b) }
    cache("<TEI><body>text</body></TEI>", Fyle::XML_TEI_TEXT, "UTF-8")
    Nokogiri.stub(:XML, document) do
      assert_includes assert_raises(RuntimeError) { @fyle.materialize }.message, "messed up"
    end
    refute @fyle.reload.local_file
  end

  test "request logging exposes validation errors on the recorded request" do
    assert @fyle.log_request(uri: "https://example.test/text", request: "GET")
    assert_empty @fyle.log_request_errors
  end

  test "GZIP materialization decompresses the actual cached bytes" do
    bytes = StringIO.new
    writer = Zlib::GzipWriter.new(bytes)
    writer.write("Compressed philosophy")
    writer.close
    cache(bytes.string, Fyle::GZIP_TEXT, nil)
    with_output_paths { assert_equal "Compressed philosophy", @fyle.materialize.last }
  end

  test "PDF extraction reads and validates the converter output" do
    ["PDF philosophy", "\xff".b].each do |converted|
      cache("PDF bytes", Fyle::PDF_TEXT, nil)
      @fyle.stub(:`, ->(command) {
                       File.binwrite(Shellwords.split(command).last, converted)
                       ""
                     }) do
        with_output_paths do
          if converted.valid_encoding? && converted.encoding == Encoding::UTF_8
            assert_equal converted, @fyle.materialize.last
            assert_equal "UTF-8", @fyle.reload.encoding
          else
            assert_includes assert_raises(RuntimeError) { @fyle.materialize }.message, "PDF rendered text"
          end
        end
      end
    end
  end

  test "missing caches and unknown formats expose a useful error" do
    assert_equal "Not cached!", assert_raises(RuntimeError) { @fyle.materialize }.message
    assert_includes @fyle.snarf, "Not cached!"
    cache("unknown", 99, nil)
    assert_equal "Unhandled content!", assert_raises(RuntimeError) { @fyle.materialize }.message
  end

  test "HTTP content types negotiate all supported formats" do
    types = {"text/plain; charset=utf-8" => Fyle::PLAIN_TEXT, "text/xml" => Fyle::XML_TEI_TEXT,
             "application/tei+xml" => Fyle::XML_TEI_TEXT, "text/html" => Fyle::HTML_TEXT,
             "application/pdf" => Fyle::PDF_TEXT, "application/x-gzip" => Fyle::GZIP_TEXT}
    types.each do |content_type, expected|
      response = {"content-type" => content_type}
      assert_equal expected, @fyle.handle_type(response, "<TEI/>")
      with_http(response, "<TEI/>") do
        assert_equal Fyle.content_type(expected), @fyle.divine_type
        assert_equal expected, @fyle.type_negotiation
      end
    end
    assert_includes @fyle.handle_type({"content-type" => "text/xml"}, "<other/>"), "random XML"
    with_http({"content-type" => "image/png"}, "bytes") { assert_includes @fyle.divine_type, "image/png" }
  end

  test "HTTP caching persists all bytes and normalizes a quoted charset" do
    @fyle.type_negotiation = Fyle::PLAIN_TEXT
    with_output_paths do
      with_http({"content-type" => 'text/plain; charset="utf-8"'}, "λόγος") do
        assert_equal true, @fyle.cache
      end
    end
    assert_equal "UTF-8", @fyle.reload.encoding
    assert_equal "λόγος".b, File.binread(@fyle.cache_file)
  end

  test "HTTP cache failures preserve the previous cache reference" do
    @fyle.type_negotiation = Fyle::PLAIN_TEXT
    @fyle.cache_file = "previous"
    with_output_paths do
      with_http({"content-type" => "text/plain"}, "content") do
        @fyle.stub(:write_binary, 1) { assert_equal false, @fyle.cache }
      end
      WRAP_HTTP.stub(:do_http2, ->(*) { "HTTP error" }) { assert_equal false, @fyle.cache }
    end
    assert_equal "previous", @fyle.cache_file
  end

  test "editing materialized content preserves the file and rejects blank input" do
    path = File.join(@directory, "edited.txt")
    File.binwrite(path, "Old text")
    @fyle.local_file = path
    refute @fyle.save_content("")
    assert @fyle.save_content("New text")
    assert_equal "New text", File.binread(path)
    @fyle.stub(:write_binary, -1) { refute @fyle.save_content("Unwritable") }
    @fyle.stub(:read_binary, "UTF-8 old") { assert @fyle.save_content("UTF-8 new") }
  end

  test "file paths preserve existing absolute paths and remap historical locations" do
    assert_nil @fyle.absolute_local_file_path
    path = File.join(@directory, "existing.txt")
    File.write(path, "text")
    mappings = {path => path, Rails.root.join("tmp/absent.txt").to_s => Rails.root.join("tmp/absent.txt").to_s,
                "/var/www/RailsApps/CorpusBuilder/tmp/old.txt" => Rails.root.join("tmp/old.txt").to_s,
                "tmp/relative.txt" => Rails.root.join("tmp/relative.txt").to_s,
                "/old/place/fallback.txt" => Rails.root.join("tmp/fallback.txt").to_s}
    mappings.each do |source, expected|
      @fyle.local_file = source
      assert_equal expected, @fyle.absolute_local_file_path
    end
  end

  test "file routes use padded corpus identifiers and preserve chunk and snapshot parameters" do
    routes = Rails.application.routes
    defaults = routes.default_url_options.dup
    routes.default_url_options[:host] = "example.test"
    id = @fyle.id.to_s.rjust(3, "0")
    assert_equal "/files/#{id}-local.txt", @fyle.plain_path
    assert_equal "http://example.test/files/#{id}-local.txt", @fyle.plain_url
    assert_equal "/files/#{id}-local/chunk.txt?chunk=2", @fyle.chunk_path(2)
    assert_equal "http://example.test/files/#{id}-local/chunk.txt?chunk=2", @fyle.chunk_url(2)
    assert_equal "/files/7/#{id}-local/snapshot.txt", Fyle.snapshot_url(7, @fyle.id)
    assert_equal "http://example.test/files/#{@fyle.id}/local", @fyle.local
    assert_equal "/files/#{@fyle.id}/strip", @fyle.strip_path
    assert_equal "http://example.test/files/#{@fyle.id}/strip", @fyle.strip_url
  ensure
    routes.default_url_options.replace(defaults)
  end

  test "display helpers describe cache local content type and decoded source URL" do
    assert_equal "no", @fyle.display_cached
    assert_equal "no", @fyle.display_localed
    assert_equal "undefined", @fyle.display_type
    @fyle.assign_attributes(cache_file: "cached", local_file: "local", type_negotiation: Fyle::PLAIN_TEXT)
    assert_equal "yes", @fyle.display_cached
    assert_equal "yes", @fyle.display_localed
    assert_equal "Plain Text", @fyle.display_type
    assert_equal "Philosophy Text", @fyle.display_what
    @fyle.URL = "https://example.test/a%20b"
    assert_equal "https://example.test/a b", @fyle.display_URL
    @fyle.URL = "https://example.test/" + "x" * 100
    assert_equal @fyle.URL[0, 24], @fyle.display_URL.split("…").first
    assert_equal "desc", Fyle.column_direction("what")
    assert_nil @fyle.sanitize
  end

  test "linked and unlinked scopes reflect actual text associations" do
    Text.create!(name: "Linked corpus text", fyle: @fyle)
    unlinked = Fyle.create!(what: "Unlinked")
    assert_includes Fyle.linked, @fyle
    refute_includes Fyle.linked, unlinked
    assert_includes Fyle.unlinked, unlinked
    refute_includes Fyle.unlinked, @fyle
  end

  test "cache names use the file label and requested extension inside the Rails temporary directory" do
    name = @fyle.gen_cache_name("txt")
    assert_equal Rails.root.join("tmp").to_s, File.dirname(name)
    assert File.basename(name).start_with?("Philosophy_Text")
    assert name.end_with?(".txt")
  end

  private

  def cache(contents, type, encoding)
    path = File.join(@directory, "cache")
    File.binwrite(path, contents)
    @fyle.update!(cache_file: path, local_file: nil, type_negotiation: type, encoding: encoding)
  end

  def with_output_paths(&block)
    generator = ->(prefix, extension) {
      @counter += 1
      File.join(@directory, "#{prefix}#{@counter}#{extension}")
    }
    Fyle.stub(:gen_tmp_name, generator, &block)
  end

  def with_http(response, body, &block)
    WRAP_HTTP.stub(:do_http2, ->(_fyle, &handler) { handler.call(URI("https://example.test/text"), nil, response, body.dup) }, &block)
  end
end
