require 'test_helper'

class CapacitiesControllerTest < ActionController::TestCase
  setup do
    @capacity = capacities(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:capacities)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create capacity" do
    assert_difference('Capacity.count') do
      post :create, capacity: { entity_id: @capacity.entity_id, relevant: @capacity.relevant }
    end

    assert_redirected_to capacity_path(assigns(:capacity))
  end

  test "should show capacity" do
    get :show, id: @capacity
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @capacity
    assert_response :success
  end

  test "should update capacity" do
    patch :update, id: @capacity, capacity: { entity_id: @capacity.entity_id, relevant: @capacity.relevant }
    assert_redirected_to capacity_path(assigns(:capacity))
  end

  test "should destroy capacity" do
    assert_difference('Capacity.count', -1) do
      delete :destroy, id: @capacity
    end

    assert_redirected_to capacities_path
  end
end
