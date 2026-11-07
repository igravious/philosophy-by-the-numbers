require 'test_helper'

class ResourceTest < ActiveSupport::TestCase
  test "resource can be read from fixtures" do
    resource = resources(:one)
    assert_not_nil resource
  end

  test "resource persists URI" do
    resource = Resource.create!(URI: "http://dbpedia.org/resource/Aristotle")
    reloaded = Resource.find(resource.id)
    assert_equal "http://dbpedia.org/resource/Aristotle", reloaded.URI
  end

  test "resource responds to metadata" do
    resource = resources(:one)
    assert_respond_to resource, :metadata
  end

  test "resource can be destroyed" do
    resource = resources(:two)
    assert_difference 'Resource.count', -1 do
      resource.destroy
    end
  end
end
