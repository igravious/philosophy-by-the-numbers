require 'test_helper'

class FilesControllerTest < ActionController::TestCase
  setup do
    @fyle = fyles(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:files) # stupidly and confusingly called @files (not @fyles) in FilesController#index
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create file" do
    skip "Requires mocking divine_type HTTP call or live test server"
  end

  test "should show file" do
    get :show, id: @fyle
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @fyle
    assert_response :success
  end

  test "should update file" do
    patch :update, id: @fyle, fyle: { URL: @fyle.URL, what: @fyle.what }
    assert_redirected_to fyle_path(assigns(:file))
  end

  test "should destroy file" do
    assert_difference('Fyle.count', -1) do
      delete :destroy, id: @fyle
    end

    assert_redirected_to fyles_path
  end
end
