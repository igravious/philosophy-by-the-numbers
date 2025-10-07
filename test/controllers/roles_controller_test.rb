require 'test_helper'

class RolesControllerTest < ActionController::TestCase
  setup do
    # Create a test role with valid attributes
    @shadow = Shadow.create!(entity_id: 9999, type: 'Philosopher')
    @capacity = Capacity.create!(entity_id: 5891, label: 'test_capacity', relevant: true)
    @role = Role.create!(shadow_id: @shadow.id, entity_id: @capacity.entity_id, label: 'test_role')
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create role" do
    assert_difference('Role.count') do
      post :create, role: { entity_id: @role.entity_id, label: @role.label, shadow_id: @role.shadow_id }
    end

    assert_redirected_to role_path(assigns(:role))
  end

  test "should show role" do
    get :show, id: @role
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @role
    assert_response :success
  end

  test "should update role" do
    patch :update, id: @role, role: { entity_id: @role.entity_id, label: @role.label, shadow_id: @role.shadow_id }
    assert_redirected_to role_path(assigns(:role))
  end

  test "should destroy role" do
    assert_difference('Role.count', -1) do
      delete :destroy, id: @role
    end

    assert_redirected_to roles_path
  end
end
