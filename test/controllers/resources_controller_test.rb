require "test_helper"
require "minitest/mock"

class ResourcesControllerTest < ActionController::TestCase
  setup do
    @resource = resources(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:resources)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create resource" do
    assert_difference("Resource.count") do
      post :create, resource: {URI: @resource.URI}
    end

    assert_redirected_to resource_path(assigns(:resource))
  end

  test "should show resource" do
    get :show, id: @resource
    assert_response :success
  end

  test "should get edit" do
    metadata = {dob: "1724", dod: "1804", alt: "Kant", nam: "Immanuel Kant", nat: "Prussia", abs: "Philosopher"}
    Resource.stub(:find, @resource) do
      @resource.stub(:metadata, metadata) do
        get :edit, id: @resource
      end
    end

    assert_response :redirect
    assert_equal "Immanuel Kant", assigns(:author).english_name
    assert_equal "1724", assigns(:author).date_of_birth
  end

  test "edit renders the resource form when metadata is unavailable" do
    Resource.stub(:find, @resource) do
      @resource.stub(:metadata, nil) do
        get :edit, id: @resource
      end
    end

    assert_response :success
    assert_nil assigns(:author)
  end

  test "should update resource" do
    patch :update, id: @resource, resource: {URI: @resource.URI}
    assert_redirected_to resource_path(assigns(:resource))
  end

  test "should destroy resource" do
    assert_difference("Resource.count", -1) do
      delete :destroy, id: @resource
    end

    assert_redirected_to resources_path
  end
end
