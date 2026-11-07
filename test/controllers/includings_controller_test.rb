require 'test_helper'

class IncludingsControllerTest < ActionController::TestCase
  setup do
    @including = includings(:one)
  end

  # Only show, create, uncreate, destroy have routes (no index/new/edit/update)

  test "should show including as json" do
    get :show, id: @including, format: :json
    assert_response :success
  end

  test "should create including" do
    assert_difference('Including.count') do
      post :create, including: { filter_id: @including.filter_id, text_id: 999 }
    end
    assert_redirected_to including_path(assigns(:including))
  end

  test "should destroy including by id" do
    assert_difference('Including.count', -1) do
      delete :destroy, id: @including
    end
    assert_redirected_to includings_url
  end

  test "should uncreate including by params" do
    assert_difference('Including.count', -1) do
      delete :uncreate, including: { filter_id: @including.filter_id, text_id: @including.text_id }
    end
    assert_redirected_to includings_url
  end
end
