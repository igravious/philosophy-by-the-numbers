require 'test_helper'

class LabelingsControllerTest < ActionController::TestCase
  setup do
    @labeling = labelings(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:labelings)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create labeling" do
    assert_difference('Labeling.count') do
      post :create, labeling: { tag_id: @labeling.tag_id, text_id: @labeling.text_id }
    end

    assert_redirected_to labeling_path(assigns(:labeling))
  end

  test "should show labeling" do
    get :show, id: @labeling
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @labeling
    assert_response :success
  end

  test "should update labeling" do
    patch :update, id: @labeling, labeling: { tag_id: @labeling.tag_id, text_id: @labeling.text_id }
    assert_redirected_to labeling_path(assigns(:labeling))
  end

  test "should destroy labeling" do
    assert_difference('Labeling.count', -1) do
      delete :destroy, id: @labeling
    end

    assert_redirected_to labelings_path
  end
end
