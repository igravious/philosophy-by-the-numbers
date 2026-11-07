class MetricInputDataset < ActiveRecord::Base
  STATUSES = %w[capturing ready invalid].freeze
  SUBJECT_TYPES = %w[Philosopher Work].freeze

  serialize :selected_entity_ids, JSON
  serialize :normalization_entity_ids, JSON
  serialize :normalization_context, JSON
  serialize :source_provenance, JSON

  belongs_to :input_run, class_name: "MetricRun"
  has_many :metric_input_records
  has_many :metric_runs

  validates :subject_type, inclusion: {in: SUBJECT_TYPES}
  validates :status, inclusion: {in: STATUSES}
  validates :schema_version, :selected_entity_ids, :normalization_entity_ids, presence: true
  validates :population_checksum, presence: true
  validates :normalization_context, :source_provenance, exclusion: {in: [nil]}
  validates :capture_completed_at, presence: true, if: :ready?

  before_update :prevent_ready_mutation
  before_destroy :prevent_ready_mutation

  def ready?
    status == "ready"
  end

  private

  def prevent_ready_mutation
    raise ActiveRecord::ReadOnlyRecord if status_was == "ready"
  end
end
