require 'test_helper'

class P::SmartsControllerTest < ActionController::TestCase
  setup do
    @p_smart = p_smarts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:p_smarts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create p_smart" do
    assert_difference('P::Smart.count') do
      post :create, p_smart: { entity_id: @p_smart.entity_id, object_id: @p_smart.object_id, redirect_id: @p_smart.redirect_id, type: @p_smart.type }
    end

    assert_redirected_to p_smart_path(assigns(:p_smart))
  end

  test "should show p_smart" do
    get :show, id: @p_smart
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @p_smart
    assert_response :success
  end

  test "should update p_smart" do
    patch :update, id: @p_smart, p_smart: { entity_id: @p_smart.entity_id, object_id: @p_smart.object_id, redirect_id: @p_smart.redirect_id, type: @p_smart.type }
    assert_redirected_to p_smart_path(assigns(:p_smart))
  end

  test "should destroy p_smart" do
    assert_difference('P::Smart.count', -1) do
      delete :destroy, id: @p_smart
    end

    assert_redirected_to p_smarts_path
  end
end
