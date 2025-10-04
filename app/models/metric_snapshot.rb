class MetricSnapshot < ActiveRecord::Base
  belongs_to :philosopher, class_name: 'Shadow', foreign_key: 'philosopher_id'
  
  validates :philosopher_id, presence: true
  validates :calculated_at, presence: true
  validates :algorithm_version, presence: true
  
  scope :latest_for_philosopher, ->(philosopher_id) { 
    where(philosopher_id: philosopher_id).order(calculated_at: :desc).limit(1) 
  }
  
  scope :by_algorithm_version, ->(version) { where(algorithm_version: version) }
  
  scope :latest_calculation, -> { order(calculated_at: :desc).limit(1) }
  
  def self.latest_measures_for_all_philosophers
    # Get the latest snapshot for each philosopher
    joins("INNER JOIN (
      SELECT philosopher_id, MAX(calculated_at) as max_calculated_at 
      FROM metric_snapshots 
      GROUP BY philosopher_id
    ) latest ON metric_snapshots.philosopher_id = latest.philosopher_id 
    AND metric_snapshots.calculated_at = latest.max_calculated_at")
  end
  
  def self.create_snapshot_for_philosopher(philosopher, algorithm_version: '2.0', danker_info: {})
    # Capture the exact weights configuration used for this calculation
    weights_config = CanonicityWeights.active.for_version(algorithm_version)
                                     .select(:source_name, :weight_value, :description)
                                     .map { |w| { w.source_name => { value: w.weight_value.to_f, description: w.description } } }
                                     .reduce(&:merge)
    
    create!(
      philosopher_id: philosopher.id,
      calculated_at: Time.current,
      measure: philosopher.measure,
      measure_pos: philosopher.measure_pos,
      danker_version: danker_info[:version],
      danker_file: danker_info[:file],
      algorithm_version: algorithm_version,
      weights_config: JSON.pretty_generate(weights_config),
      notes: "Calculated using Linear Weighted Combination algorithm v#{algorithm_version}"
    )
  end
  
  def parsed_weights_config
    return {} if weights_config.blank?
    JSON.parse(weights_config)
  rescue JSON::ParserError
    {}
  end
end