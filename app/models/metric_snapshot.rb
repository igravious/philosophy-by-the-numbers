class MetricSnapshot < ActiveRecord::Base
  # Polymorphic-style association but without using Rails polymorphic feature
  # due to STI conflicts. shadow_type stores 'Philosopher' or 'Work'
  belongs_to :shadow, foreign_key: :shadow_id, class_name: 'Shadow'

  validates :shadow_id, presence: true
  validates :shadow_type, presence: true
  validates :calculated_at, presence: true
  validates :algorithm_version, presence: true

  scope :for_philosophers, -> { where(shadow_type: 'Philosopher') }
  scope :for_works, -> { where(shadow_type: 'Work') }

  scope :latest_for_shadow, ->(shadow_id, shadow_type = 'Philosopher') {
    where(shadow_id: shadow_id, shadow_type: shadow_type).order(calculated_at: :desc).limit(1)
  }

  # Backward compatibility
  scope :latest_for_philosopher, ->(philosopher_id) {
    latest_for_shadow(philosopher_id, 'Philosopher')
  }

  scope :by_algorithm_version, ->(version) { where(algorithm_version: version) }

  scope :latest_calculation, -> { order(calculated_at: :desc).limit(1) }

  def self.latest_measures_for_all_philosophers
    # Get the latest snapshot for each philosopher
    joins("INNER JOIN (
      SELECT shadow_id, MAX(calculated_at) as max_calculated_at
      FROM metric_snapshots
      WHERE shadow_type = 'Philosopher'
      GROUP BY shadow_id
    ) latest ON metric_snapshots.shadow_id = latest.shadow_id
    AND metric_snapshots.calculated_at = latest.max_calculated_at
    AND metric_snapshots.shadow_type = 'Philosopher'")
  end

  def self.latest_measures_for_all_works
    # Get the latest snapshot for each work
    joins("INNER JOIN (
      SELECT shadow_id, MAX(calculated_at) as max_calculated_at
      FROM metric_snapshots
      WHERE shadow_type = 'Work'
      GROUP BY shadow_id
    ) latest ON metric_snapshots.shadow_id = latest.shadow_id
    AND metric_snapshots.calculated_at = latest.max_calculated_at
    AND metric_snapshots.shadow_type = 'Work'")
  end
  
  def self.create_snapshot_for_philosopher(philosopher, algorithm_version: '2.0', danker_info: {})
    # Capture the exact weights configuration used for this calculation
    weights_config = CanonicityWeights.active.for_version(algorithm_version)
                                     .select(:source_name, :weight_value, :description)
                                     .map { |w| { w.source_name => { value: w.weight_value.to_f, description: w.description } } }
                                     .reduce(&:merge)

    create!(
      shadow_id: philosopher.id,
      shadow_type: 'Philosopher',
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

  def self.create_snapshot_for_philosopher_with_measure(philosopher, calculated_measure, algorithm_version: '2.0', danker_info: {})
    # Capture the exact weights configuration used for this calculation
    weights_config = CanonicityWeights.active.for_version(algorithm_version)
                                     .select(:source_name, :weight_value, :description)
                                     .map { |w| { w.source_name => { value: w.weight_value.to_f, description: w.description } } }
                                     .reduce(&:merge)

    create!(
      shadow_id: philosopher.id,
      shadow_type: 'Philosopher',
      calculated_at: Time.current,
      measure: calculated_measure,
      measure_pos: nil, # Will be calculated later based on ranking
      danker_version: danker_info[:version],
      danker_file: danker_info[:file],
      algorithm_version: algorithm_version,
      weights_config: JSON.pretty_generate(weights_config),
      notes: "Calculated using Linear Weighted Combination algorithm v#{algorithm_version} (snapshot only)"
    )
  end

  def self.create_snapshot_for_work(work, calculated_measure, algorithm_version: '2.0-work', danker_info: {})
    # Capture the exact weights configuration used for this calculation
    weights_config = CanonicityWeights.active.for_version(algorithm_version)
                                     .select(:source_name, :weight_value, :description)
                                     .map { |w| { w.source_name => { value: w.weight_value.to_f, description: w.description } } }
                                     .reduce(&:merge) || {}

    create!(
      shadow_id: work.id,
      shadow_type: 'Work',
      calculated_at: Time.current,
      measure: calculated_measure,
      measure_pos: nil, # Will be calculated later based on ranking
      danker_version: danker_info[:version],
      danker_file: danker_info[:file],
      algorithm_version: algorithm_version,
      weights_config: JSON.pretty_generate(weights_config),
      notes: "Calculated using Work-specific canonicity algorithm v#{algorithm_version}"
    )
  end
  
  def parsed_weights_config
    return {} if weights_config.blank?
    JSON.parse(weights_config)
  rescue JSON::ParserError
    {}
  end
end