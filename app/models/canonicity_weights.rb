class CanonicityWeights < ActiveRecord::Base
  validates :algorithm_version, presence: true
  validates :source_name, presence: true, uniqueness: { scope: :algorithm_version }
  validates :weight_value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  scope :active, -> { where(active: true) }
  scope :for_version, ->(version) { where(algorithm_version: version) }
  
  def self.weights_for_version(version = '2.0')
    active.for_version(version).pluck(:source_name, :weight_value).to_h
  end
  
  def self.active_version
    active.order(:algorithm_version).last&.algorithm_version || '2.0'
  end
  
  def self.sum_for_version(version = '2.0')
    active.for_version(version).sum(:weight_value)
  end
end