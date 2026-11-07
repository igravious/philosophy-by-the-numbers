require 'test_helper'

class MetricSnapshotTest < ActiveSupport::TestCase
  setup do
    @philosopher = create_test_philosopher(entity_id: 970020)
    @work = create_test_work(entity_id: 870020)
    @snapshot = MetricSnapshot.create!(
      shadow_id: @philosopher.id,
      shadow_type: "Philosopher",
      calculated_at: Time.current,
      canonicity_weight_algorithm_version: "2.0",
      danker_version: "2023-06-01",
      danker_file: "test_danker.gz",
      danker_score: 0.5,
      linkcount: 100,
      mention_count: 1,
      reference_work_flags: '{"stanford":false}',
      measure: 0.5,
      measure_pos: 1,
      notes: "Test snapshot"
    )
  end

  test "metric snapshot belongs to shadow" do
    assert_respond_to @snapshot, :shadow
    assert_equal @philosopher, @snapshot.shadow
  end

  test "metric snapshot validates presence of shadow_id" do
    snapshot = MetricSnapshot.new(shadow_type: "Philosopher", calculated_at: Time.current, canonicity_weight_algorithm_version: "2.0")
    assert_not snapshot.valid?
    assert snapshot.errors[:shadow_id].any?
  end

  test "metric snapshot validates presence of shadow_type" do
    snapshot = MetricSnapshot.new(shadow_id: 1, calculated_at: Time.current, canonicity_weight_algorithm_version: "2.0")
    assert_not snapshot.valid?
    assert snapshot.errors[:shadow_type].any?
  end

  test "metric snapshot validates presence of calculated_at" do
    snapshot = MetricSnapshot.new(shadow_id: 1, shadow_type: "Philosopher", canonicity_weight_algorithm_version: "2.0")
    assert_not snapshot.valid?
    assert snapshot.errors[:calculated_at].any?
  end

  test "metric snapshot validates presence of canonicity_weight_algorithm_version" do
    snapshot = MetricSnapshot.new(shadow_id: 1, shadow_type: "Philosopher", calculated_at: Time.current)
    assert_not snapshot.valid?
    assert snapshot.errors[:canonicity_weight_algorithm_version].any?
  end

  test "for_philosophers scope returns only philosopher snapshots" do
    MetricSnapshot.for_philosophers.each do |s|
      assert_equal "Philosopher", s.shadow_type
    end
  end

  test "for_works scope returns only work snapshots" do
    MetricSnapshot.create!(
      shadow_id: @work.id, shadow_type: "Work", calculated_at: Time.current,
      canonicity_weight_algorithm_version: "2.0-work", danker_version: "test",
      danker_file: "test", danker_score: 0.3, linkcount: 50, mention_count: 1,
      reference_work_flags: '{}', measure: 0.3
    )
    MetricSnapshot.for_works.each do |s|
      assert_equal "Work", s.shadow_type
    end
  end

  test "latest_for_shadow returns most recent snapshot" do
    latest = MetricSnapshot.latest_for_shadow(@philosopher.id, 'Philosopher')
    assert_equal 1, latest.count
    assert_equal @snapshot, latest.first
  end

  test "latest_for_philosopher is backward compatible" do
    latest = MetricSnapshot.latest_for_philosopher(@philosopher.id)
    assert_equal 1, latest.count
  end

  test "by_algorithm_version filters by version" do
    MetricSnapshot.by_algorithm_version("2.0").each do |s|
      assert_equal "2.0", s.canonicity_weight_algorithm_version
    end
  end

  test "latest_calculation returns one record" do
    latest = MetricSnapshot.latest_calculation
    assert latest.count <= 1
  end

  test "weights_config returns hash from canonicity_weights" do
    config = @snapshot.weights_config
    assert_kind_of Hash, config
  end

  test "latest_measures_for_all_philosophers returns relation" do
    results = MetricSnapshot.latest_measures_for_all_philosophers
    assert_respond_to results, :count
  end

  test "latest_measures_for_all_works returns relation" do
    results = MetricSnapshot.latest_measures_for_all_works
    assert_respond_to results, :count
  end

  test "run snapshots preserve nil primitive inputs" do
    snapshot = MetricSnapshot.create!(
      shadow_id: @philosopher.id,
      shadow_type: "Philosopher",
      calculated_at: Time.current,
      canonicity_weight_algorithm_version: "2.0",
      danker_version: "unknown",
      danker_file: "unknown",
      reference_work_flags: "{}",
      measure: 0.0
    )

    snapshot.reload
    assert_nil snapshot.danker_score
    assert_nil snapshot.linkcount
    assert_nil snapshot.mention_count
  end

  test "deleting an entity retains snapshot evidence" do
    @philosopher.destroy

    assert MetricSnapshot.exists?(@snapshot.id)
    assert_nil @snapshot.reload.shadow
  end
end
