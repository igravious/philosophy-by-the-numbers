require "test_helper"
require "minitest/mock"
require "tmpdir"
require "open3"
require "open-uri"
require_relative "../support/rake_task_testing"

class DankerUpdateTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  Reply = Struct.new(:code, :body)

  setup do
    @directory = Dir.mktmpdir("danker-tasks-")
    @root = Pathname.new(@directory)
    FileUtils.mkdir_p(@root.join("db"))
    use_rake_tasks(Rails.root.join("lib/tasks/danker_update.rake"))
    @receiver = Rake::Task["danker:update"].actions.first.binding.receiver
    @version = "2026-10-01"
    @data = @root.join("db", "danker_#{@version}")
    @link = @root.join("db/danker")
  end

  teardown do
    restore_rake_tasks
    FileUtils.remove_entry(@directory)
  end

  test "version listing distinguishes absent data and marks the current symlink" do
    assert_includes run_task("list"), "No danker data found"
    FileUtils.mkdir_p(@data)
    FileUtils.mkdir_p(@root.join("db/danker_2025-01-01"))
    FileUtils.ln_s("danker_#{@version}", @link)
    output = run_task("list")
    assert_includes output, "#{@version} <- current"
    assert output.index(@version) < output.index("2025-01-01")
  end

  test "index refresh selects the newest version and repairs a stale symlink" do
    FileUtils.mkdir_p(@data)
    File.write(@data.join("sample.rank.bz2"), "placeholder")
    FileUtils.ln_s("missing-old-version", @link)
    with_index do
      output = run_task("update")
      assert_includes output, "Already have latest version: #{@version}"
    end
    assert_equal "danker_#{@version}", @link.readlink.to_s
  end

  test "index errors fail explicitly without creating data directories" do
    [Reply.new("503", "offline"), Reply.new("200", "<html>No datasets</html>")].each do |response|
      Net::HTTP.stub(:get_response, response) do
        assert_equal 1, assert_raises(SystemExit) { run_task("update") }.status
      end
    end
    Net::HTTP.stub(:get_response, ->(*) { raise IOError, "unreachable" }) do
      assert_equal 1, assert_raises(SystemExit) { run_task("update") }.status
    end
    refute @link.symlink?
  end

  test "downloads persist rank data tolerate optional stats failures and update the symlink" do
    FileUtils.ln_s("old-version", @link)
    download = ->(url, &block) do
      raise IOError, "Stats unavailable" if url.end_with?("stats.txt")
      block.call(StringIO.new("downloaded rank data"))
    end
    URI.stub(:open, download) { with_index { assert_includes run_task("update"), "Successfully downloaded" } }
    assert_equal "downloaded rank data", File.binread(@data.join("#{@version}.allwiki.links.rank.bz2"))
    assert_equal "danker_#{@version}", @link.readlink.to_s
  end

  test "failed downloads remove an empty candidate version and preserve the old symlink" do
    FileUtils.ln_s("old-version", @link)
    URI.stub(:open, ->(*) { raise IOError, "offline" }) do
      with_index { assert_equal 1, assert_raises(SystemExit) { run_task("update") }.status }
    end
    refute @data.exist?
    assert_equal "old-version", @link.readlink.to_s
  end

  test "real compressed data becomes numeric alphabetical and CSV lookup files" do
    source = "Q100\t0.1\nQ2\t0.2\nQ10\t0.3\n"
    compressed_file(source)
    assert_includes run_task("process_files"), "Successfully processed 3 records"
    assert_equal "Q2\t0.2\nQ10\t0.3\nQ100\t0.1\n", File.read(@data.join("#{@version}.allwiki.links.q"))
    assert_equal "Q10,0.3\nQ100,0.1\nQ2,0.2\n", File.read(@data.join("#{@version}.allwiki.links.c.alphanum.csv"))
    csv = @data.join("#{@version}.allwiki.links.c.alphanum.csv")
    File.utime(Time.now + 60, Time.now + 60, csv)
    assert_includes run_task("process_files"), "already exists and is up to date"
  end

  test "processing rejects missing data and skips versions without a rank archive" do
    assert_equal 1, assert_raises(SystemExit) { run_task("process_files") }.status
    FileUtils.mkdir_p(@data)
    assert_includes run_task("process_files"), "no .rank.bz2 file found"
    assert_equal false, @receiver.send(:verify_danker_data_format, @data)
  end

  test "processing reports each failed output stage and unexpected command errors" do
    compressed_file("Q2\t0.2\n")
    original_system = @receiver.method(:system)
    failures = {"bzcat" => "Failed to decompress", "sort -k" => "Failed to create Q-sorted", "sort -d" => "Failed to sort alphabetically", "sed " => "Failed to create CSV"}
    failures.each do |pattern, message|
      Dir.glob(@data.join("*")).reject { |path| path.end_with?(".bz2") }.each { |path| FileUtils.rm(path) }
      execute = ->(command) { command.include?(pattern) ? false : original_system.call(command) }
      @receiver.stub(:system, execute) { assert_includes run_task("process_files"), message }
    end
    @receiver.stub(:system, ->(*) { raise IOError, "command failed" }) do
      assert_includes run_task("process_files"), "command failed"
    end
  end

  test "processing detects mismatched output line counts" do
    compressed_file("Q2\t0.2\nQ3\t0.3\n")
    counts = %w[2 1 2 2]
    @receiver.stub(:`, ->(*) { counts.shift }) { assert_includes run_task("process_files"), "Line count mismatch" }
  end

  test "optional compressed reader checks sample records and rejects invalid formats" do
    FileUtils.mkdir_p(@data)
    path = @data.join("sample.rank.bz2")
    with_compressed_reader do
      {"Q42\t0.25\ninvalid\n" => true, "invalid\n" => false, ("invalid\n" * 11 + "Q42\t0.25\n") => false}.each do |contents, expected|
        File.write(path, contents)
        capture_io { assert_equal expected, @receiver.send(:verify_danker_data_format, @data) }
      end
    end
  end

  test "optional compressed reader failures return an unsuccessful verification" do
    FileUtils.mkdir_p(@data)
    File.write(@data.join("sample.rank.bz2"), "corrupt")
    with_compressed_reader do |reader|
      reader.stub(:open, ->(*) { raise IOError, "corrupt archive" }) do
        capture_io { assert_equal false, @receiver.send(:verify_danker_data_format, @data) }
      end
    end
  end

  private

  def with_compressed_reader
    original = Object.const_get(:Bzip2) if Object.const_defined?(:Bzip2)
    Object.send(:remove_const, :Bzip2) if original
    package = Module.new
    ffi = Module.new
    reader = Class.new
    reader.define_singleton_method(:open) { |file, &block| block.call(StringIO.new(file.read)) }
    ffi.const_set(:Reader, reader)
    package.const_set(:FFI, ffi)
    Object.const_set(:Bzip2, package)
    original_require = @receiver.method(:require)
    @receiver.stub(:require, ->(feature) { (feature == "bzip2-ffi") ? true : original_require.call(feature) }) { yield reader }
  ensure
    Object.send(:remove_const, :Bzip2)
    Object.const_set(:Bzip2, original) if original
  end

  def with_index(&block)
    body = "<html>https://danker.s3.amazonaws.com/2025-01-01.allwiki.links.rank.bz2 https://danker.s3.amazonaws.com/#{@version}.allwiki.links.rank.bz2</html>"
    Net::HTTP.stub(:get_response, Reply.new("200", body), &block)
  end

  def run_task(name)
    task = Rake::Task["danker:#{name}"]
    task.reenable
    Rails.stub(:root, @root) { capture_io { task.invoke }.first }
  end

  def compressed_file(contents)
    FileUtils.mkdir_p(@data)
    bytes, stderr, status = Open3.capture3("bzip2", "-c", stdin_data: contents)
    assert status.success?, stderr
    File.binwrite(@data.join("#{@version}.allwiki.links.rank.bz2"), bytes)
  end
end
