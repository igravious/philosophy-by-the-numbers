require "test_helper"
require "minitest/mock"
require "tempfile"

class QuestionQueriesTest < ActionController::TestCase
  tests QuestionsController

  setup do
    @figure = create_test_philosopher
    @figure.names.create!(lang: "en", label: "Query Figure")
    @other = create_test_philosopher
    @other.names.create!(lang: "en", label: "Other Figure")
    @country = P::P27.create!(entity_id: @figure.entity_id, redirect_id: @figure.entity_id, object_id: 145, object_label: "Ireland")
    P::P27.create!(entity_id: @other.entity_id, redirect_id: @other.entity_id, object_id: 84, object_label: "Other Country")
    P::D1.create!(entity_id: @figure.entity_id, redirect_id: @figure.entity_id, object_id: 145, object_label: "School One")
    P::D1.create!(entity_id: @other.entity_id, redirect_id: @other.entity_id, object_id: 84, object_label: "School Two")
  end

  test "generic feature endpoints group their actual STI property classes" do
    {countries: P::P27, all_countries: P::J27, schools: P::D1, interests: P::D2,
     subjects: P::D3, birth_places: P::P19, death_places: P::P20, languages: P::P1412}.each do |action, model|
      unless [P::P27, P::D1].include?(model)
        model.create!(entity_id: @figure.entity_id, redirect_id: @figure.entity_id, object_id: 999, object_label: "Coverage Feature")
      end
      get action
      assert_response :success
      assert assigns(:feature_list).any?, action
      assert assigns(:feature_labels).any?, action
    end
    get :places
    assert_response :success
    get :all_places
    assert_response :success
  end

  test "feature labels filter a table and selected identifiers filter the result records" do
    get :countries, label: "Ireland"
    assert_response :success
    assert_equal({145 => "Ireland"}, assigns(:feature_labels))
    get :countries, features: ["145", "84"]
    assert_equal [@figure.entity_id, @other.entity_id].sort, assigns(:entity_ids).sort
    get :countries, features: []
    assert_response :success
    assert_equal "Countries", assigns(:page_title)
  end

  test "feature labels and identifiers treat SQL-looking input as data" do
    get :countries, label: "' OR 1=1 --"
    assert_empty assigns(:feature_list)
    get :schools, features: ['145" OR 1=1 --']
    assert_empty assigns(:entity_ids)
  end

  test "validated specific queries also restrict the philosopher population" do
    get :specific, multiplex: "schools", ids: [@figure.entity_id.to_s], features: ["145"]
    assert_response :success
    assert_equal [@figure.entity_id], assigns(:entity_ids)
    assert_equal "Specific School", assigns(:grouping)
  end

  test "Irish queries include matching property families and preserve original identities" do
    P::P19.create!(entity_id: @other.entity_id, redirect_id: @other.entity_id, object_id: 27, object_label: "Northern Ireland")
    get :irish
    assert_response :success
    assert_equal [@figure.entity_id, @other.entity_id].sort, assigns(:entity_ids).sort
    assert_equal "Irish", assigns(:grouping)
  end

  test "instance tables use actual labels and counts" do
    P::P31.create!(entity_id: @figure.entity_id, redirect_id: @figure.entity_id, object_id: 5, object_label: "Human")
    get :instances
    assert_response :success
    assert_equal "Human", assigns(:feature_labels)[5]
  end

  test "saved question filters restore typed feature identifiers" do
    filter = QuestionMetaFilter.create!(filter: "Coverage Question")
    MetaFilterPair.create!(meta_filter: filter, key: "multiplex", value: "countries")
    MetaFilterPair.create!(meta_filter: filter, key: "features", value: ["145"])
    get :from_filter, id: filter.id

    assert_response :success
    assert_equal [145], assigns(:features)
    assert_equal "Ireland", assigns(:feature_labels)[145]
    assert_select "#feature145" do |elements|
      refute elements.first["disabled"]
    end
    assert assigns(:whereami).end_with?("/questions/countries")
  end

  test "question queries redirect saved selection operations through the shared filter concern" do
    filter = QuestionMetaFilter.create!(filter: "Existing Question")
    get :countries, meta: [filter.filter]
    assert_redirected_to bulk_meta_filter_pair_path(filter.id)
    get :countries, meta: ["New Question"]
    assert_response :redirect
    assert_includes response.location, "/bulk/meta_filter_pairs/new"
  end

  test "upload staging preserves the file contents for inspection" do
    file = Tempfile.new(["question-ids", ".txt"])
    file.write(" Q145\nQ84 \n")
    file.close
    upload = Rack::Test::UploadedFile.new(file.path, "text/plain")
    post :uploaded, filename: upload
    assert_response :success
    assert_equal "Q145\nQ84", assigns(:box)
    assert_empty assigns(:entity_ids)
  ensure
    file&.unlink
  end

  test "pasted identifiers ignore blank lines and normalize whitespace" do
    post :uploaded, fileText: "\n Q145   Ireland\n\nQ84 Other\n"
    assert_response :success
    assert_equal %w[145 84], assigns(:entity_ids)
    post :uploaded, fileText: ""
    assert_response :success
    assert_empty assigns(:entity_ids)
  end

  test "legacy property reports preserve labels counts and grouping" do
    Property.create!(entity_id: @figure.entity_id, entity_label: "Query Figure", property_id: 737, data_id: 145, data_label: "Influence")
    get :influences
    assert_response :success
    assert_includes assigns(:feature_list), ["Influence", 1]
    Property.create!(entity_id: @figure.entity_id, entity_label: "Query Figure", property_id: 27, data_id: 145, data_label: "Ireland")
    @controller.params = ActionController::Parameters.new(connection: "Related", data_id: 145)
    @controller.stub(:render, nil) do
      @controller.dumb_irish
      assert_equal [@figure.entity_id], @controller.instance_variable_get(:@entity_ids)
      @controller.dumb_thinkers
      assert_equal "Related", @controller.instance_variable_get(:@grouping)
      @controller.dumb_countries
      assert_equal "Countries", @controller.instance_variable_get(:@page_title)
    end
  end
end
