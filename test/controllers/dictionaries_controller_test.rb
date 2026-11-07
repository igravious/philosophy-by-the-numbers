require 'test_helper'

class DictionariesControllerTest < ActionController::TestCase
  setup do
    @dictionary = dictionaries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dictionaries)
    assert_select "a[href=?]", canonicity_path, text: "Canonicity dashboard"
  end

  test "index counts flags from philosopher attrs and shadows" do
    @dictionary.update!(encyclopedia_flag: "kemerling")
    dictionaries(:two).update!(encyclopedia_flag: "routledge")
    create_test_philosopher(kemerling: true, routledge: true)
    create_test_philosopher(kemerling: true, routledge: false)
    create_test_philosopher(kemerling: false, routledge: true)

    get :index

    assert_response :success
    assert_equal 2, assigns(:philosopher_counts)["kemerling"]
    assert_equal 2, assigns(:philosopher_counts)["routledge"]
  end

  test "index labels inactive legacy sources by status" do
    @dictionary.update!(encyclopedia_flag: "oxford2")
    CanonicityWeights.create!(algorithm_version: "2.0", source_name: "oxford2",
      weight_value: 0.2, active: false)

    get :index

    assert_response :success
    assert_select "span", text: "Inactive legacy source", count: 1
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dictionary" do
    assert_difference('Dictionary.count') do
      post :create, dictionary: { URI: @dictionary.URI, contact: @dictionary.contact, current_editor: @dictionary.current_editor, long_title: @dictionary.long_title, organisation: @dictionary.organisation, title: @dictionary.title }
    end

    assert_redirected_to dictionary_path(assigns(:dictionary))
  end

  test "should show dictionary" do
    get :show, id: @dictionary
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dictionary
    assert_response :success
  end

  test "should update dictionary" do
    patch :update, id: @dictionary, dictionary: { URI: @dictionary.URI, contact: @dictionary.contact, current_editor: @dictionary.current_editor, long_title: @dictionary.long_title, organisation: @dictionary.organisation, title: @dictionary.title }
    assert_redirected_to dictionary_path(assigns(:dictionary))
  end

  test "should destroy dictionary" do
    assert_difference('Dictionary.count', -1) do
      delete :destroy, id: @dictionary
    end

    assert_redirected_to dictionaries_path
  end
end
