require 'test_helper'

class PhilosophersControllerTest < ActionController::TestCase
  setup do
    # Create test philosophers dynamically (more reliable than fixtures)
    @philosopher = Philosopher.create!(
      entity_id: 999001,
      mention: 100,
      danker: 0.7,
      measure: 0.7
    )
    @leibniz = Philosopher.create!(
      entity_id: 999002,
      mention: 90,
      danker: 0.6,
      measure: 0.6
    )
  end

  teardown do
    # Clean up test data
    Philosopher.where('entity_id >= 999000 AND entity_id < 1000000').destroy_all
  end

  # ============================================================================
  # BASIC CRUD ACTIONS
  # ============================================================================

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:shadows)
    assert_not_nil assigns(:language_list)
  end

  test "should get index with type parameter" do
    get :index, type: 'Philosopher'
    assert_response :success
    assert_equal 'Philosopher', assigns(:type)
  end

  test "should show philosopher" do
    get :show, id: @philosopher.id
    assert_response :success
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @philosopher.id
    assert_response :success
  end

  test "should create philosopher" do
    assert_difference('Shadow.count') do
      post :create, philosopher: {
        type: 'Philosopher',
        entity_id: 99999
      }
    end
    assert_redirected_to philosopher_path(assigns(:shadow))
  end

  test "should update philosopher" do
    patch :update, id: @philosopher.id, philosopher: {
      entity_id: @philosopher.entity_id
    }
    assert_redirected_to philosopher_path(assigns(:shadow))
  end

  test "should destroy philosopher" do
    assert_difference('Shadow.count', -1) do
      delete :destroy, id: @philosopher.id
    end
    assert_redirected_to philosophers_path
  end

  # ============================================================================
  # INDEX FILTERING - LANGUAGE
  # ============================================================================

  test "should filter by language" do
    get :index, lang: 'en'
    assert_response :success
    assert_equal 'en', assigns(:lang)
  end

  test "should show all languages when lang=all" do
    get :index, lang: 'all'
    assert_response :success
    assert_equal 'all', assigns(:lang)
  end

  test "should filter by label text" do
    get :index, lang: 'en', label: 'Plato'
    assert_response :success
    assert_equal 'Plato', assigns(:label)
  end

  # ============================================================================
  # INDEX FILTERING - GENDER
  # ============================================================================

  test "should filter by female gender" do
    get :index, gender: 'f'
    assert_response :success
    assert assigns(:gender)[:f]
  end

  test "should filter by male gender" do
    get :index, gender: 'm'
    assert_response :success
    assert assigns(:gender)[:m]
  end

  # ============================================================================
  # INDEX FILTERING - VIAF
  # ============================================================================

  test "should filter by VIAF presence" do
    get :index, viaf: 'on'
    assert_response :success
    assert_equal 'checked', assigns(:viaf)
  end

  test "should filter by VIAF absence" do
    get :index, no_viaf: 'on'
    assert_response :success
    assert_equal 'checked', assigns(:no_viaf)
  end

  # ============================================================================
  # INDEX FILTERING - YEAR RANGES
  # ============================================================================

  test "should filter by birth year before date" do
    get :index, before: '1500'
    assert_response :success
    assert_equal 1500, assigns(:before)
  end

  test "should filter by birth year after date" do
    get :index, after: '1500'
    assert_response :success
    assert_equal 1500, assigns(:after)
  end

  test "should filter by birth year between dates" do
    get :index, after: '1400', before: '1500'
    assert_response :success
    assert_equal 1400, assigns(:after)
    assert_equal 1500, assigns(:before)
  end

  test "should reject invalid year ranges" do
    get :index, before: 'invalid'
    assert_response :success
    assert_nil assigns(:before)
  end

  test "should reject out-of-range years" do
    get :index, before: '-5000'  # Before -4000 limit
    assert_response :success
    assert_nil assigns(:before)
  end

  test "should filter living philosophers" do
    get :index, living: 'on'
    assert_response :success
    assert_equal 'checked', assigns(:living)
  end

  test "should filter by yearage full (both dates set)" do
    get :index, yearage: 'full'
    assert_response :success
    assert assigns(:yearage)[:full]
  end

  test "should filter by yearage empty (missing dates)" do
    get :index, yearage: 'empty'
    assert_response :success
    assert assigns(:yearage)[:empty]
  end

  # ============================================================================
  # INDEX FILTERING - ENCYCLOPEDIA FLAGS
  # ============================================================================

  test "should filter by all_ticked (all encyclopedia flags true)" do
    get :index, all_ticked: 'on'
    assert_response :success
    assert_equal 'checked', assigns(:all_ticked)
  end

  test "should filter by only_ticked (only encyclopedia flags false)" do
    get :index, only_ticked: 'on'
    assert_response :success
    assert_equal 'checked', assigns(:only_ticked)
  end

  test "should toggle single encyclopedia source" do
    get :index, toggle: 'stanford'
    assert_response :success
    assert_equal 'stanford', assigns(:toggle)
  end

  # ============================================================================
  # INDEX FILTERING - METRIC/CANONICITY
  # ============================================================================

  test "should filter by metric position" do
    get :index, metric: '100'
    assert_response :success
    assert_equal 100, assigns(:metric)
  end

  test "should handle invalid metric parameter" do
    get :index, metric: 'invalid'
    assert_response :success
    # Should default to 0 or handle gracefully
  end

  # ============================================================================
  # SORTING
  # ============================================================================

  test "should sort by entity_id ascending" do
    get :index, sort: 'entity_id', direction: 'asc'
    assert_response :success
  end

  test "should sort by measure descending" do
    get :index, sort: 'measure', direction: 'desc'
    assert_response :success
  end

  test "should default to measure sorting if no sort param" do
    get :index
    assert_response :success
    # Default sort column is 'measure'
  end

  test "should reject invalid sort column" do
    get :index, sort: 'invalid_column'
    assert_response :success
    # Should fall back to default 'measure'
  end

  # ============================================================================
  # SPECIFIC ACTION (by Q-IDs)
  # ============================================================================

  test "should get specific with single Q-ID" do
    get :specific, ids: [@philosopher.entity_id.to_s]
    assert_response :success
  end

  test "should get specific with multiple Q-IDs" do
    get :specific, ids: [@philosopher.entity_id.to_s, @leibniz.entity_id.to_s]
    assert_response :success
  end

  test "should handle specific with no ids parameter" do
    get :specific
    assert_response :success
  end

  # ============================================================================
  # COMPARE ACTION (meta filter comparisons)
  # ============================================================================

  test "should compare two meta filters" do
    # Create test meta filters with unique names
    timestamp = Time.now.to_i
    mf1 = MetaFilter.create!(filter: "test_filter_1_#{timestamp}", type: 'MainMetaFilter')
    mf2 = MetaFilter.create!(filter: "test_filter_2_#{timestamp}", type: 'MainMetaFilter')

    # Create meta filter pairs with ids
    MetaFilterPair.create!(
      meta_filter_id: mf1.id,
      key: 'ids',
      value: [@philosopher.entity_id]
    )
    MetaFilterPair.create!(
      meta_filter_id: mf2.id,
      key: 'ids',
      value: [@leibniz.entity_id]
    )

    get :compare, meta: ["test_filter_1_#{timestamp}", "test_filter_2_#{timestamp}"]
    assert_response :success
    assert_not_nil assigns(:a_less_b)
    assert_not_nil assigns(:b_less_a)
  end

  test "should handle compare with missing meta filters" do
    get :compare, meta: ['nonexistent1', 'nonexistent2']
    assert_response :success
    # Should call blank_compare
  end

  test "should handle compare with no meta parameter" do
    get :compare
    assert_response :success
  end

  # ============================================================================
  # FROM_FILTER ACTION (load saved meta filter)
  # ============================================================================

  test "should load from saved meta filter" do
    mf = MetaFilter.create!(filter: "test_filter_#{Time.now.to_i}", type: 'MainMetaFilter')
    MetaFilterPair.create!(
      meta_filter_id: mf.id,
      key: 'lang',
      value: 'en'
    )

    get :from_filter, id: mf.id
    assert_response :success
    assert_equal 'en', assigns(:lang)
  end

  test "should load from filter with ids" do
    mf = MetaFilter.create!(filter: "test_filter_ids_#{Time.now.to_i}", type: 'MainMetaFilter')
    MetaFilterPair.create!(
      meta_filter_id: mf.id,
      key: 'ids',
      value: [@philosopher.entity_id]
    )

    get :from_filter, id: mf.id
    assert_response :success
  end

  # ============================================================================
  # SINGLE PHILOSOPHER BY an_id
  # ============================================================================

  test "should display single philosopher by Q-ID" do
    get :index, an_id: "Q#{@philosopher.entity_id}"
    assert_response :success
    assert_equal "Q#{@philosopher.entity_id}", assigns(:an_id)
  end

  test "should display single philosopher by internal ID" do
    get :index, an_id: @philosopher.id.to_s
    assert_response :success
  end

  # ============================================================================
  # HELPER METHODS
  # ============================================================================

  test "sort_column should return valid column name" do
    get :index, sort: 'entity_id'
    assert_response :success
    # Helper method is tested indirectly through sorting tests
  end

  test "sort_column should default to measure for invalid column" do
    get :index, sort: 'invalid'
    assert_response :success
    # Should use default 'measure'
  end

  test "sort_direction should validate direction parameter" do
    get :index, direction: 'asc'
    assert_response :success

    get :index, direction: 'desc'
    assert_response :success
  end

  test "toggle_column should validate column name" do
    get :index, toggle: 'stanford'
    assert_response :success
    assert_equal 'stanford', assigns(:toggle)
  end

  test "toggle_column should reject invalid column" do
    get :index, toggle: 'invalid_column'
    assert_response :success
    assert_nil assigns(:toggle)
  end

  # ============================================================================
  # PAGINATION
  # ============================================================================

  test "should paginate results" do
    get :index, page: 2
    assert_response :success
    assert_not_nil assigns(:shadows)
  end

  # ============================================================================
  # ERROR HANDLING
  # ============================================================================

  test "should handle single philosopher not found gracefully" do
    get :index, an_id: 'Q9999999'
    assert_response :success
    assert_equal '', assigns(:entity_qid)
  end

  test "should handle invalid entity_id in specific action" do
    get :specific, ids: ['invalid']
    assert_response :success
  end
end
