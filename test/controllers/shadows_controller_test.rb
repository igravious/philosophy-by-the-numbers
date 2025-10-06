require 'test_helper'

class ShadowsControllerTest < ActionController::TestCase
  setup do
    @shadow = shadows(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:shadows)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create shadow" do
    assert_difference('Shadow.count') do
      post :create, shadow: { entity_id: @shadow.entity_id, type: @shadow.type }
    end

    assert_redirected_to shadow_path(assigns(:shadow))
  end

  test "should show shadow" do
    get :show, id: @shadow
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @shadow
    assert_response :success
  end

  test "should update shadow" do
    patch :update, id: @shadow, shadow: { entity_id: @shadow.entity_id, type: @shadow.type }
    assert_redirected_to shadow_path(assigns(:shadow))
  end

  test "should destroy shadow" do
    assert_difference('Shadow.count', -1) do
      delete :destroy, id: @shadow
    end

    assert_redirected_to shadows_path
  end
end
