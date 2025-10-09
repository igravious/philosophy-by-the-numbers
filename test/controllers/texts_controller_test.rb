require 'test_helper'

class TextsControllerTest < ActionController::TestCase
  fixtures :texts
  setup do
		# how to call this before only some tests and not each test
    @text = texts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:texts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create text" do
    assert_difference('Text.count') do
      post :create, text: { edition_year: @text.edition_year, name: @text.name, original_year: @text.original_year }
    end

    assert_redirected_to text_path(assigns(:text))
  end

  test "should show text" do
    get :show, id: @text
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @text
    assert_response :success
  end

  test "should update text" do
    patch :update, id: @text, text: { edition_year: @text.edition_year, name: @text.name, original_year: @text.original_year }
    assert_redirected_to text_path(assigns(:text))
  end

  test "should destroy text" do
    assert_difference('Text.count', -1) do
      delete :destroy, id: @text
    end

    assert_redirected_to texts_path
  end

	test "texts as xml" do
		# setup is called and load fixture :one into @text
    # @text = texts(:one)
		@text = nil
		response = get :index, format: 'xml', parts: true

		assert_response :success
		assert_match /application\/xml/, @response.content_type

		# Verify XML structure
		assert_match /<\?xml version="1\.0" encoding="UTF-8"\?>/, response.body
		assert_match /<sxf>/, response.body
		assert_match /<conference url="">/, response.body
		assert_match /<acronym>PHIL<\/acronym>/, response.body
		assert_match /<name>Philosophical texts<\/name>/, response.body
		assert_match /<description>Corpus of philosophical texts<\/description>/, response.body
		assert_match /<events>/, response.body
	end
end
