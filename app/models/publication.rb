class Publication < ActiveRecord::Base
  belongs_to :metric_run

  validates :metric_run, :subject_type, presence: true
  validates :subject_type, inclusion: {in: %w[Philosopher Work]}

  before_update :prevent_mutation
  before_destroy :prevent_mutation

  def self.current_for(subject_type)
    where(subject_type: subject_type).order(id: :desc).first
  end

  private

  def prevent_mutation
    raise ActiveRecord::ReadOnlyRecord
  end
end
