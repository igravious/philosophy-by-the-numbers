require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_select "a[href=?]", canonicity_path, text: "Canonicity dashboard"
  end

  test "should get about" do
    get :about
    assert_response :success
  end

  test "welcome redirects to about" do
    get :welcome
    assert_redirected_to about_path
  end

  test "should get export" do
    get :export
    assert_response :success
    assert_not_nil assigns(:total)
    assert_not_nil assigns(:saffron)
    assert_not_nil assigns(:lda)
    assert_equal 'Export Related Stuff', assigns(:page_title)
  end

  test "should get inquiry" do
    get :inquiry
    assert_response :success
    assert_not_nil assigns(:inquiries)
  end

  test "should get questions" do
    get :questions
    assert_response :success
    assert_equal 'Questions & Answers', assigns(:page_title)
    assert_not_nil assigns(:inquiries)
  end

  test "should get collect" do
    get :collect
    assert_response :success
  end

  test "should get dracula" do
    get :dracula
    assert_response :success
  end

  test "should get pome" do
    get :pome
    assert_response :success
    assert_nil assigns(:words)
  end

  test "should get paper" do
    get :paper
    assert_response :success
    assert_not_nil assigns(:delivery)
    assert_instance_of Delivery, assigns(:delivery)
  end

  test "should get dashboard" do
    get :dashboard
    assert_response :success
    assert_equal 'Database Dashboard', assigns(:page_title)
    assert_not_nil assigns(:table_counts)
    assert_kind_of Hash, assigns(:table_counts)
  end

  test "dashboard table_counts is sorted by count descending" do
    get :dashboard
    counts = assigns(:table_counts).values
    assert_equal counts, counts.sort.reverse
  end

  test "search without query renders without error" do
    get :search
    assert_response :success
  end

  test "springy without term renders selection page" do
    get :springy
    assert_response :success
  end
end
