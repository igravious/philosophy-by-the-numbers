class MetricInputRecord < ActiveRecord::Base
  serialize :input_payload, JSON

  belongs_to :metric_input_dataset
  belongs_to :shadow
  has_many :metric_snapshots

  validates :metric_input_dataset, :shadow_id, :shadow_type, :entity_id, :entity_label, :input_payload, presence: true
  validates :shadow_type, inclusion: {in: %w[Philosopher Work]}
  validates :shadow_id, uniqueness: {scope: :metric_input_dataset_id}
  validate :population_membership

  before_update :prevent_mutation
  before_destroy :prevent_ready_dataset_mutation

  private

  def population_membership
    errors.add(:base, "record must belong to selected or normalization population") unless selected? || normalization?
  end

  def prevent_mutation
    raise ActiveRecord::ReadOnlyRecord if metric_input_dataset_id_changed? || metric_input_dataset.ready?
  end

  def prevent_ready_dataset_mutation
    raise ActiveRecord::ReadOnlyRecord if metric_input_dataset.ready?
  end
end
