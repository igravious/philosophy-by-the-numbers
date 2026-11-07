require "test_helper"

class P::SmartsControllerTest < ActionController::TestCase
  setup do
    @p_smart = P::P27.create!(entity_id: 970_080, redirect_id: 970_080,
      object_id: 970_081, object_label: "Test country")
  end

  test "lists STI property records through the base resource route" do
    get :index

    assert_response :success
    assert_includes assigns(:p_smarts), @p_smart
    assert_includes response.body, p_smart_path(@p_smart)
  end

  test "shows a record using all components of its composite key" do
    get :show, id: @p_smart.to_param

    assert_response :success
    assert_equal @p_smart, assigns(:p_smart)
  end

  test "renders the new form" do
    get :new

    assert_response :success
    assert_select "form[action=?]", p_smarts_path
  end

  test "edits an STI record through the base resource route" do
    get :edit, id: @p_smart.to_param

    assert_response :success
    assert_select "form[action=?]", p_smart_path(@p_smart)
    assert_select "input[name=?]", "p_smart[entity_id]"
  end

  test "creates an STI property record" do
    assert_difference("P::P27.count") do
      post :create, p_smart: {entity_id: 970_082, redirect_id: 970_082,
                              object_id: 970_083, type: "P::P27"}
    end

    assert_redirected_to p_smart_path(assigns(:p_smart))
  end

  test "updates a property record without changing its composite identity" do
    patch :update, id: @p_smart.to_param, p_smart: {entity_id: 970_084}

    assert_redirected_to p_smart_path(@p_smart)
    assert_equal 970_084, @p_smart.reload.entity_id
    assert_equal 970_080, @p_smart.redirect_id
  end

  test "destroys only the addressed composite key" do
    other = P::P27.create!(entity_id: 970_080, redirect_id: 970_080, object_id: 970_085)

    assert_difference("P::P27.count", -1) do
      delete :destroy, id: @p_smart.to_param
    end

    assert_redirected_to p_smarts_path
    assert P::P27.exists?(other.id)
    refute P::P27.exists?(@p_smart.id)
  end
end
