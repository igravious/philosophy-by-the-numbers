require "test_helper"
require "minitest/mock"

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
    with_plain_text_response do
      assert_difference("Fyle.count") do
        post :create, fyle: {URL: "http://example.com/new.txt", what: "New text"}
      end
    end

    file = assigns(:file)
    assert_redirected_to fyle_path(file)
    assert_equal Fyle::PLAIN_TEXT, file.reload.type_negotiation
    assert file.handled
  end

  test "unsupported content does not create a file" do
    response = ->(_file, &block) { block.call(nil, nil, {"content-type" => "application/zip"}, "") }

    WRAP_HTTP.stub(:do_http2, response) do
      assert_no_difference("Fyle.count") do
        post :create, fyle: {URL: "http://example.com/archive.zip", what: "Unsupported archive"}
      end
    end

    assert_response :success
    assert_match(/do not yet know how to handle/, flash[:alert])
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
    with_plain_text_response do
      patch :update, id: @fyle, fyle: {URL: @fyle.URL, what: "Updated text"}
    end
    assert_redirected_to fyle_path(assigns(:file))
    assert_equal "Updated text", @fyle.reload.what
    assert_equal Fyle::PLAIN_TEXT, @fyle.type_negotiation
  end

  test "should destroy file" do
    assert_difference("Fyle.count", -1) do
      delete :destroy, id: @fyle
    end

    assert_redirected_to fyles_path
  end

  private

  def with_plain_text_response(&action)
    response = ->(_file, &block) { block.call(nil, nil, {"content-type" => "text/plain"}, "Test text") }
    WRAP_HTTP.stub(:do_http2, response, &action)
  end
end
