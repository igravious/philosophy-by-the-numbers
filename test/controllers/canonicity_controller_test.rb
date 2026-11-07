require "test_helper"

class CanonicityControllerTest < ActionController::TestCase
  test "index exposes active and inactive configuration for UAT" do
    CanonicityWeights.create!(algorithm_version: "2.1", source_name: "runes",
      weight_value: nil, active: false)
    CanonicityWeights.create!(algorithm_version: "2.1", source_name: "stanford",
      weight_value: 0.1, active: true)

    get :index

    assert_response :success
    assert_equal "2.1", assigns(:algorithm_version)
    assert assigns(:weights).any?(&:active?)
    assert assigns(:weights).any? { |weight| !weight.active? && weight.weight_value.nil? }
    assert_select "h1", text: "Canonicity"
    assert_select "td", text: "NULL", count: 1
    assert_select "span", text: "Inactive legacy source", count: 1
    assert_select "code", text: "philosopher-v2"
    assert_select "code", text: "work-v2"
    assert_select "option[selected='selected']", text: "2.1-philosopher"
    assert_select "select#algorithm_version[style*='width: auto']"
  end

  test "index displays weights to two decimal places" do
    CanonicityWeights.create!(algorithm_version: "2.1", source_name: "kemerling",
      weight_value: 0.066225, active: true)

    get :index

    assert_response :success
    assert_select "td", text: "0.07"
  end

  test "index selects an alternative algorithm version" do
    CanonicityWeights.create!(algorithm_version: "2.0-work", source_name: "genre_other",
      weight_value: 0.5, active: true)

    get :index, algorithm_version: "2.0-work"

    assert_response :success
    assert_equal "2.0-work", assigns(:algorithm_version)
    assert_equal ["genre_other"], assigns(:weights).map(&:source_name)
    assert_select "option[selected='selected']", text: "2.0-work"
  end

  test "index exposes signal definitions and infrastructure counts" do
    CanonicitySignal.create!(algorithm_version: "2.1", name: "danker", source: "Wikipedia",
      description: "Time-varying PageRank input", subject_to_change: true, used_in_formula: true)

    get :index

    assert_response :success
    assert_equal ["danker"], assigns(:signals).map(&:name)
    assert_equal 0, assigns(:infrastructure_counts)[:input_datasets]
    assert_equal 0, assigns(:infrastructure_counts)[:metric_runs]
    assert_equal 0, assigns(:infrastructure_counts)[:source_events]
    assert_equal 0, assigns(:infrastructure_counts)[:publications]
    assert_select "h2", text: "Signals"
    assert_select "h2", text: "Metric infrastructure"
    assert_select "td", text: "Time-varying PageRank input"
  end

  test "index explains what each section represents" do
    get :index

    assert_response :success
    assert_select "p.intro-description", text: /inspect how canonicity is configured/
    assert_select "p.section-description", count: 8
    assert_select "p.section-description", text: /formula implementations/
    assert_select "p.section-description", text: /how much each source contributes/
    assert_select "p.section-description", text: /raw inputs available to the calculators/
    assert_select "p.section-description", text: /execution evidence exists/
    assert_select "h2", text: "Calculator identities"
    assert_select "h2", text: "Formulae"
    assert_select "code", text: "normalized_measure = (mention / max_mention) × (rank / max_rank) × total_source_weight"
    assert_select "code", text: "normalized_measure = (mention / max_mention) × (rank / max_rank) × genre × (sourcey + exists)"
    assert_select "code", text: "display_measure = normalized_measure × 10,000,000"
    assert_select "code", text: "S₀ × S₁ × S₂ × … × Sₙ"
    assert_select "h3", text: "Scalar signals"
    assert_select "h3", text: "Bitset signals"
    assert_select "p", text: /Every factor must be between 0 and 1 inclusive/
  end

  test "index exposes dataset capture and source event evidence" do
    dataset = MetricInputDataset.create!(
      subject_type: "Philosopher", status: "ready", schema_version: "1.0",
      selected_entity_ids: [1, 2], normalization_entity_ids: [1], normalization_context: {},
      source_provenance: {"artifact" => "test"}, population_checksum: "checksum",
      capture_completed_at: Time.current
    )
    philosopher = create_test_philosopher(entity_id: 42)
    SourceEvent.create!(
      source_name: "danker", import_identity: "danker-test", artifact_identity: "danker.tsv",
      artifact_checksum: "abc", shadow_id: philosopher.id, shadow_type: "Philosopher",
      entity_id: philosopher.entity_id, attribute_name: "danker", old_value: nil, new_value: 0.75,
      provenance: {}, imported_at: Time.current
    )

    get :index

    assert_response :success
    assert_equal [dataset.id], assigns(:datasets).map(&:id)
    assert_equal ["danker-test"], assigns(:source_events).map(&:import_identity)
    assert_select "h2", text: "Input datasets"
    assert_select "h2", text: "Source events"
    assert_select "td", text: "ready"
    assert_select "td", text: "danker.tsv"
    assert_select "td", text: "NULL"
    assert_select "details summary", text: "View"
    assert_select "details", text: /Normalization context/
    assert_select "details", text: /Source provenance/
  end

  test "run page displays execution evidence and replays without writes" do
    {"routledge" => 0.17, "stanford" => 0.10, "all_bonus" => 0.08}.each do |source, weight|
      weight_record = CanonicityWeights.find_or_initialize_by(algorithm_version: "2.1", source_name: source)
      weight_record.update!(weight_value: weight, active: true)
    end
    philosopher = create_test_philosopher(mention: 100, danker: 1.0, routledge: true, stanford: true)
    dataset = Canonicity::DatasetCapture.new(
      subject_type: "Philosopher", selected_entity_ids: [philosopher.id], normalization_entity_ids: [philosopher.id]
    ).call
    run = Canonicity::MetricRunCalculator.new(dataset: dataset).call

    get :index
    assert_select "h2", text: "Metric runs"
    assert_select "a[href=?]", canonicity_run_path(run), text: "Show"

    get :show, id: run.id
    assert_response :success
    assert_equal run, assigns(:run)
    assert_select "td", text: "0.7.0"

    original_count = MetricSnapshot.count
    post :replay, id: run.id

    assert_response :success
    assert assigns(:report).matches?
    assert_equal original_count, MetricSnapshot.count
    assert_select "p", text: "REPLAY_MATCH"
  end
end
