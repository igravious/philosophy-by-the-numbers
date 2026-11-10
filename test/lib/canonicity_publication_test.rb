require "test_helper"
require "minitest/mock"
require_relative "../support/canonicity_run_helpers"

class CanonicityPublicationTest < ActiveSupport::TestCase
  include CanonicityRunHelpers

  setup do
    @first = create_test_philosopher(entity_id: 42, measure: -1.0, measure_pos: 90)
    @second = create_test_philosopher(entity_id: 43, measure: -2.0, measure_pos: 91)
    @run = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first, @second],
      measures: {@first.id => 200.0, @second.id => 100.0}
    )
  end

  test "eligibility accepts a completed full-population run with verified dense ranks" do
    eligibility = Canonicity::Publication.new(run: @run).eligibility

    assert eligibility.eligible?
    assert_empty eligibility.reasons
    assert_not eligibility.dependency_mismatch?
  end

  test "publication atomically updates current measures and ranks and appends history" do
    original_snapshots = @run.metric_snapshots.order(:shadow_id).pluck(:shadow_id, :measure, :measure_pos)

    publication = Canonicity::Publication.new(run: @run).call

    assert_equal publication, Publication.current_for("Philosopher")
    assert_equal @run, publication.metric_run
    assert_equal [200.0, 1], [@first.reload.measure, @first.measure_pos]
    assert_equal [100.0, 2], [@second.reload.measure, @second.measure_pos]
    assert_equal original_snapshots, @run.metric_snapshots.order(:shadow_id).pluck(:shadow_id, :measure, :measure_pos)
  end

  test "publication preserves floating point measures exactly" do
    run = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first, @second],
      measures: {@first.id => 7.487195963407554, @second.id => 6.872579156440906},
      version: "0.7.1"
    )

    Canonicity::Publication.new(run: run).call

    run.metric_snapshots.each do |snapshot|
      assert_equal snapshot.measure, Philosopher.find(snapshot.shadow_id).measure
    end
  end

  test "partial and stale populations are not publishable" do
    partial = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first],
      measures: {@first.id => 200.0},
      selected_entity_ids: [@first.id],
      normalization_entity_ids: [@first.id],
      version: "0.7.1"
    )

    reasons = Canonicity::Publication.new(run: partial).eligibility.reasons
    assert reasons.any? { |reason| reason.include?("selected population") }
    assert reasons.any? { |reason| reason.include?("normalization population") }
    assert_raises(Canonicity::PublicationError) { Canonicity::Publication.new(run: partial).call }
    assert_equal(-1.0, @first.reload.measure)

    create_test_philosopher(entity_id: 44)
    stale_reasons = Canonicity::Publication.new(run: @run).eligibility.reasons
    assert stale_reasons.any? { |reason| reason.include?("current Philosopher population") }
  end

  test "incomplete runs non-finite measures and incorrect dense ranks are rejected" do
    @run.update_column(:status, "running")
    assert_includes Canonicity::Publication.new(run: @run).eligibility.reasons, "run is not completed"
    @run.update_column(:status, "completed")

    snapshot = @run.metric_snapshots.find_by!(shadow_id: @first.id)
    snapshot.update_column(:measure_pos, 99)
    assert_includes Canonicity::Publication.new(run: @run).eligibility.reasons, "dense ranks do not match snapshot measures"
    snapshot.update_column(:measure_pos, 1)

    snapshots = @run.metric_snapshots.to_a
    nonfinite_snapshot = snapshots.find { |item| item.shadow_id == @first.id }
    nonfinite_snapshot.stub(:measure, Float::INFINITY) do
      MetricSnapshot.stub(:where, snapshots) do
        assert_includes Canonicity::Publication.new(run: @run).eligibility.reasons, "snapshot measures are not all finite"
      end
    end
  end

  test "an interruption rolls back every current value and the publication record" do
    Publication.stub(:create!, ->(*) { raise Interrupt }) do
      assert_raises(Interrupt) { Canonicity::Publication.new(run: @run).call }
    end

    assert_equal 0, Publication.count
    assert_equal [-1.0, 90], [@first.reload.measure, @first.measure_pos]
    assert_equal [-2.0, 91], [@second.reload.measure, @second.measure_pos]
  end

  test "republishing an older run appends history and makes it current" do
    newer = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first, @second],
      measures: {@first.id => 50.0, @second.id => 300.0},
      version: "0.7.1"
    )
    first_publication = Canonicity::Publication.new(run: @run).call
    Canonicity::Publication.new(run: newer).call
    republished = Canonicity::Publication.new(run: @run).call

    assert_equal 3, Publication.where(subject_type: "Philosopher").count
    assert_operator republished.id, :>, first_publication.id
    assert_equal @run, Publication.current_for("Philosopher").metric_run
    assert_equal [200.0, 1], [@first.reload.measure, @first.measure_pos]
  end

  test "Work dependency mismatch warns without blocking publication" do
    Canonicity::Publication.new(run: @run).call
    dependency = create_completed_metric_run(
      subject_type: "Philosopher",
      shadows: [@first, @second],
      measures: {@first.id => 200.0, @second.id => 100.0},
      version: "0.7.1"
    )
    work = create_test_work(entity_id: 44, measure: -3.0)
    works = Work.order(:id).to_a
    measures = works.each_with_object({}) { |item, result| result[item.id] = 10.0 }
    measures[work.id] = 400.0
    work_run = create_completed_metric_run(
      subject_type: "Work",
      shadows: works,
      measures: measures,
      input_run: dependency
    )

    service = Canonicity::Publication.new(run: work_run)
    assert service.eligibility.eligible?, service.eligibility.reasons.inspect
    assert service.eligibility.dependency_mismatch?
    assert_match(/Philosopher run 0.7.1/, service.eligibility.dependency_warning)
    assert_match(/0.7.0/, service.eligibility.dependency_warning)

    publication = service.call
    assert_equal work_run, Publication.current_for("Work").metric_run
    assert_equal work_run, publication.metric_run
    assert_equal 400.0, work.reload.measure
  end
end
