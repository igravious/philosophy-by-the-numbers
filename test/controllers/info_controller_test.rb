require 'test_helper'

class InfoControllerTest < ActionController::TestCase
  test "should get schema" do
    get :schema
    assert_response :success
    assert_equal 'yo!', assigns(:schema)
    assert_equal 'Schema', assigns(:page_title)
  end

  test "schema renders without layout" do
    get :schema
    assert_response :success
  end
end
