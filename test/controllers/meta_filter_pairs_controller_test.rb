require 'test_helper'

class MetaFilterPairsControllerTest < ActionController::TestCase
  setup do
    @meta_filter_pair = meta_filter_pairs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:meta_filter_pairs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create meta_filter_pair" do
    assert_difference('MetaFilterPair.count') do
      post :create, meta_filter_pair: { key: "unique_new_key", meta_filter_id: @meta_filter_pair.meta_filter_id, value: @meta_filter_pair.value }
    end

    assert_redirected_to meta_filter_pair_path(assigns(:meta_filter_pair))
  end

  test "should show meta_filter_pair" do
    get :show, id: @meta_filter_pair
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @meta_filter_pair
    assert_response :success
  end

  test "should update meta_filter_pair" do
    patch :update, id: @meta_filter_pair, meta_filter_pair: { key: @meta_filter_pair.key, meta_filter_id: @meta_filter_pair.meta_filter_id, value: @meta_filter_pair.value }
    assert_redirected_to meta_filter_pair_path(assigns(:meta_filter_pair))
  end

  test "should destroy meta_filter_pair" do
    assert_difference('MetaFilterPair.count', -1) do
      delete :destroy, id: @meta_filter_pair
    end

    assert_redirected_to meta_filter_pairs_path
  end
end
