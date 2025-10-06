require 'test_helper'

class MetaFiltersControllerTest < ActionController::TestCase
  setup do
    @meta_filter = meta_filters(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:meta_filters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create meta_filter" do
    assert_difference('MetaFilter.count') do
      post :create, meta_filter: { filter: @meta_filter.filter, key: @meta_filter.key, value: @meta_filter.value }
    end

    assert_redirected_to meta_filter_path(assigns(:meta_filter))
  end

  test "should show meta_filter" do
    get :show, id: @meta_filter
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @meta_filter
    assert_response :success
  end

  test "should update meta_filter" do
    patch :update, id: @meta_filter, meta_filter: { filter: @meta_filter.filter, key: @meta_filter.key, value: @meta_filter.value }
    assert_redirected_to meta_filter_path(assigns(:meta_filter))
  end

  test "should destroy meta_filter" do
    assert_difference('MetaFilter.count', -1) do
      delete :destroy, id: @meta_filter
    end

    assert_redirected_to meta_filters_path
  end
end
