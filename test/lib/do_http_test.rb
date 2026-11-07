require "test_helper"
require "minitest/mock"
require "tempfile"
require "net/http"
require_relative "../../lib/do_http"

class DoHttpTest < ActiveSupport::TestCase
  Document = Struct.new(:URI, :accept_log, :logged, :log_request_errors) do
    def log_request(**values)
      self.logged = values
      accept_log
    end
  end

  def document(url, accept_log: true)
    Document.new(url, accept_log, nil, Struct.new(:messages).new(["logging failed"]))
  end

  def response(code = "200")
    Struct.new(:body, :headers, :response).new("philosophical text", {"content-type" => "text/plain"}, Struct.new(:code).new(code))
  end

  test "HTTP requests yield their content after recording the request" do
    file = document("https://example.com/work.txt")
    received = nil
    result = HTTParty.stub(:get, response) do
      WRAP_HTTP.do_http2(file) do |uri, request, headers, body|
        received = [uri.host, request, headers, body]
        :processed
      end
    end

    assert_equal :processed, result
    assert_equal "example.com", received[0]
    assert_equal "text/plain", received[2]["content-type"]
    assert_equal "philosophical text", received[3]
    assert_includes file.logged.fetch(:uri), "example.com"
  end

  test "HTTP error responses do not yield content" do
    file = document("http://example.com/work.txt")
    result = HTTParty.stub(:get, response("404")) do
      WRAP_HTTP.do_http2(file) { flunk "An unsuccessful response must not be processed" }
    end

    assert_includes result, "404"
  end

  test "failed request logging prevents processing" do
    file = document("http://example.com/work.txt", accept_log: false)
    result = HTTParty.stub(:get, response) do
      WRAP_HTTP.do_http2(file) { flunk "An unrecorded request must not be processed" }
    end

    assert_includes result, "unprocessable_entity"
    assert_includes result, "logging failed"
  end

  test "unsupported schemes produce an explanatory result" do
    assert_includes WRAP_HTTP.do_http2(document("ftp://example.com/work.txt")), "FTP"
  end

  test "local files yield their content without HTTP" do
    Tempfile.create("corpus-http") do |file|
      file.write("Local philosophical text")
      file.flush
      result = WRAP_HTTP.do_http2(document("file://#{file.path}")) do |uri, _request, _headers, body|
        assert_equal file.path, uri.path
        body.upcase
      end

      assert_equal "LOCAL PHILOSOPHICAL TEXT", result
    end
  end

  test "legacy HTTP requests process a successful logged response" do
    file = document("http://example.com/work.txt")
    reply = Net::HTTPOK.new("1.1", "200", "OK")
    reply.instance_variable_set(:@read, true)
    reply.body = "Legacy text"
    http = Object.new
    http.define_singleton_method(:request) { |_request| reply }

    result = Net::HTTP.stub(:new, http) { WRAP_HTTP.do_http(file) { |_uri, _request, _response, body| body } }

    assert_equal "Legacy text", result
    assert file.logged
  end

  test "legacy HTTP failures report status and logging failures" do
    [true, false].each do |accept_log|
      file = document("http://example.com/work.txt", accept_log: accept_log)
      reply = Net::HTTPNotFound.new("1.1", "404", "Not found")
      reply.instance_variable_set(:@read, true)
      reply.body = "missing"
      http = Object.new
      http.define_singleton_method(:request) { |_request| reply }

      result = Net::HTTP.stub(:new, http) { WRAP_HTTP.do_http(file) { flunk "Must not process failed content" } }

      assert_includes result, accept_log ? "404" : "unprocessable_entity"
    end
  end

  test "legacy HTTPS and unsupported schemes report their limitations" do
    assert_equal "protocol HTTPS unsupported yet", WRAP_HTTP.do_http(document("https://example.com"))
    assert_includes WRAP_HTTP.do_http(document("ftp://example.com")), "FTP"
  end
end
