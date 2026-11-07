class MetricRun < ActiveRecord::Base
  STATUSES = %w[running completed failed].freeze
  SUBJECT_TYPES = %w[Philosopher Work].freeze

  serialize :weights_config, JSON
  serialize :signal_config, JSON
  serialize :source_provenance, JSON

  belongs_to :metric_input_dataset
  belongs_to :parent_run, class_name: "MetricRun"
  has_many :child_runs, class_name: "MetricRun", foreign_key: :parent_run_id
  has_many :metric_snapshots
  has_many :publications
  has_many :input_datasets, class_name: "MetricInputDataset", foreign_key: :input_run_id

  validates :subject_type, inclusion: {in: SUBJECT_TYPES}
  validates :status, inclusion: {in: STATUSES}
  validates :version, :major, :minor, :patch, :metric_input_dataset, presence: true
  validates :calculator_identity, :configuration_version, :configuration_fingerprint, presence: true
  validates :started_at, presence: true
  validates :weights_config, :signal_config, :source_provenance, exclusion: {in: [nil]}
  validates :version, uniqueness: {scope: :subject_type}
  validates :major, :minor, :patch, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :major, uniqueness: {scope: [:subject_type, :minor, :patch]}
  validates :completed_at, presence: true, if: :completed?
  validate :version_matches_components

  before_update :prevent_completed_mutation
  before_destroy :prevent_completed_mutation

  def completed?
    status == "completed"
  end

  private

  def version_matches_components
    expected = [major, minor, patch].join(".")
    errors.add(:version, "must match major, minor, and patch components") unless version == expected
  end

  def prevent_completed_mutation
    raise ActiveRecord::ReadOnlyRecord if status_was == "completed"
  end
end
