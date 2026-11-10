require "test_helper"
require_relative "../support/canonicity_run_helpers"

class CanonicityControllerTest < ActionController::TestCase
  include CanonicityRunHelpers
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
    assert_select "p.section-description", count: 10
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

  test "index exposes publication eligibility history and run comparison" do
    first = create_test_philosopher(entity_id: 42)
    second = create_test_philosopher(entity_id: 43)
    from_run = create_completed_metric_run(
      subject_type: "Philosopher", shadows: [first, second], measures: {first.id => 100.0, second.id => 50.0}
    )
    to_run = create_completed_metric_run(
      subject_type: "Philosopher", shadows: [first, second], measures: {first.id => 25.0, second.id => 200.0}, version: "0.7.1"
    )
    publication = Canonicity::Publication.new(run: from_run).call

    get :index, from_run_id: from_run.id, to_run_id: to_run.id

    assert_response :success
    assert_equal [publication], assigns(:publications).to_a
    assert_equal publication, assigns(:current_publications).fetch("Philosopher")
    assert assigns(:publication_eligibilities).fetch(from_run.id).eligible?
    assert_equal 2, assigns(:comparison).changes.length
    assert_select "h2", text: "Publication history"
    assert_select "h2", text: "Run comparison"
    assert_select "select#from_run_id"
    assert_select "select#to_run_id"
    assert_select "td", text: "Current"
    assert_select "td", text: "Eligible"
  end

  test "index batches population and snapshot queries for publication eligibility" do
    first = create_test_philosopher(entity_id: 42)
    second = create_test_philosopher(entity_id: 43)
    measures = {first.id => 100.0, second.id => 50.0}
    create_completed_metric_run(subject_type: "Philosopher", shadows: [first, second], measures: measures)
    create_completed_metric_run(subject_type: "Philosopher", shadows: [first, second], measures: measures, version: "0.7.1")
    works = Work.order(:id).to_a
    work_measures = works.each_with_object({}) { |work, result| result[work.id] = 10.0 }
    create_completed_metric_run(subject_type: "Work", shadows: works, measures: work_measures)
    queries = []
    callback = ->(_name, _started, _finished, _id, payload) { queries << payload[:sql] }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get :index }

    assert_response :success
    population_queries = queries.count { |sql| sql.include?('SELECT "shadows"."id" FROM "shadows"') }
    snapshot_queries = queries.count { |sql| sql.include?('SELECT "metric_snapshots".* FROM "metric_snapshots" WHERE "metric_snapshots"."metric_run_id"') }
    assert_equal 2, population_queries
    assert_equal 1, snapshot_queries
  end

  test "run page publishes an eligible full-population run" do
    first = create_test_philosopher(entity_id: 42, measure: -1.0)
    second = create_test_philosopher(entity_id: 43, measure: -2.0)
    run = create_completed_metric_run(
      subject_type: "Philosopher", shadows: [first, second], measures: {first.id => 100.0, second.id => 50.0}
    )

    get :show, id: run.id
    assert_response :success
    assert assigns(:publication_eligibility).eligible?
    assert_select "form[action=?]", publish_canonicity_run_path(run)
    assert_select "input[type='submit'][value='Publish this run']"

    post :publish, id: run.id

    assert_redirected_to canonicity_run_path(run)
    assert_equal run, Publication.current_for("Philosopher").metric_run
    assert_equal 100.0, first.reload.measure
    assert_equal 50.0, second.reload.measure
    assert_match(/Published Philosopher run/, flash[:notice])
  end

  test "stale runs explain ineligibility and cannot be published" do
    first = create_test_philosopher(entity_id: 42, measure: -1.0)
    run = create_completed_metric_run(subject_type: "Philosopher", shadows: [first], measures: {first.id => 100.0})
    create_test_philosopher(entity_id: 43)

    get :show, id: run.id
    assert_response :success
    assert_not assigns(:publication_eligibility).eligible?
    assert_select "form[action=?]", publish_canonicity_run_path(run), count: 0
    assert_select "li", text: /selected population does not match current Philosopher population/

    post :publish, id: run.id

    assert_redirected_to canonicity_run_path(run)
    assert_equal 0, Publication.count
    assert_equal(-1.0, first.reload.measure)
    assert_match(/selected population/, flash[:alert])
  end

  test "run snapshots are paginated one hundred at a time" do
    philosophers = 101.times.map { |index| create_test_philosopher(entity_id: 1000 + index) }
    measures = philosophers.each_with_index.each_with_object({}) do |(philosopher, index), result|
      result[philosopher.id] = 1000.0 - index
    end
    run = create_completed_metric_run(subject_type: "Philosopher", shadows: philosophers, measures: measures)

    get :show, id: run.id
    assert_response :success
    assert_equal 101, assigns(:snapshots).total_count
    assert_select "table.snapshots tbody tr", count: 100
    assert_select ".pagination"

    get :show, id: run.id, page: 2
    assert_response :success
    assert_select "table.snapshots tbody tr", count: 1
  end

  test "run page warns when a Work dependency is not currently published" do
    create_test_work(entity_id: 44)
    works = Work.order(:id).to_a
    measures = works.each_with_object({}) { |item, result| result[item.id] = 10.0 }
    run = create_completed_metric_run(subject_type: "Work", shadows: works, measures: measures)

    get :show, id: run.id

    assert_response :success
    assert assigns(:publication_eligibility).dependency_mismatch?
    assert_select "p.dependency-warning", text: /no currently published Philosopher run/
  end
end
