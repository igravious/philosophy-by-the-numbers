require 'test_helper'

class FyleTest < ActiveSupport::TestCase
  test "fyle can be read from fixtures" do
    fyle = fyles(:one)
    assert_not_nil fyle
  end

  test "fyle has one text" do
    fyle = fyles(:one)
    assert_respond_to fyle, :text
  end

  test "fyle defines content type constants" do
    assert_equal 1, Fyle::PLAIN_TEXT
    assert_equal 2, Fyle::XML_TEI_TEXT
    assert_equal 3, Fyle::PDF_TEXT
    assert_equal 4, Fyle::HTML_TEXT
    assert_equal 5, Fyle::GZIP_TEXT
  end

  test "fyle CONTENT_TYPE lookup table is complete" do
    assert_kind_of Array, Fyle::CONTENT_TYPE
    assert_equal 5, Fyle::CONTENT_TYPE.length
    assert_equal "Plain Text", Fyle::CONTENT_TYPE.first[0]
  end

  test "fyle FILE_EXT lookup table is complete" do
    assert_kind_of Array, Fyle::FILE_EXT
    assert_equal 5, Fyle::FILE_EXT.length
    assert_equal "txt", Fyle::FILE_EXT.first[0]
  end

  test "fyle MIME_TYPE lookup table is complete" do
    assert_kind_of Array, Fyle::MIME_TYPE
    assert_equal "text/plain", Fyle::MIME_TYPE[1]
    assert_equal "application/pdf", Fyle::MIME_TYPE[3]
  end

  test "fyle URI returns URL" do
    fyle = fyles(:one)
    assert_equal fyle.URL, fyle.URI
  end

  test "fyle can be created" do
    fyle = Fyle.new(URL: "http://example.com/test.txt", what: 1)
    assert fyle.save
  end

  test "fyle can be destroyed" do
    fyle = Fyle.create!(URL: "http://example.com/temp.txt")
    assert_difference 'Fyle.count', -1 do
      fyle.destroy
    end
  end

  test "fyle log_request creates http request logger entry" do
    fyle = fyles(:one)
    assert_difference 'HttpRequestLogger.count', 1 do
      fyle.log_request(uri: "http://example.com", request: "GET /")
    end
  end
end
