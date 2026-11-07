module Canonicity
  class MetricRunCalculator
    def initialize(dataset:, configuration_version: nil, parent_run: nil, calculator_identity: nil)
      @dataset = dataset
      @configuration_version = configuration_version || default_configuration_version
      @parent_run = parent_run
      @calculator_identity = calculator_identity || default_calculator_identity
    end

    def call
      MetricOperationLock.synchronize { execute }
    end

    private

    def execute
      raise ArgumentError, "Metric calculation requires a ready dataset" unless @dataset.ready?

      validate_configuration_subject!
      weights = CanonicityWeights.weights_for_version(@configuration_version)
      raise ArgumentError, "No active weights for configuration #{@configuration_version}" if weights.empty?

      signal_config = default_signal_config
      fingerprint = configuration_fingerprint(weights, signal_config)
      @run = MetricRun.create!(
        subject_type: @dataset.subject_type,
        version: next_version(fingerprint),
        major: @version_components[0],
        minor: @version_components[1],
        patch: @version_components[2],
        metric_input_dataset: @dataset,
        parent_run: @parent_run,
        calculator_identity: @calculator_identity,
        configuration_version: @configuration_version,
        configuration_fingerprint: fingerprint,
        status: "running",
        started_at: Time.current,
        weights_config: weights,
        signal_config: signal_config,
        source_provenance: {
          "dataset_id" => @dataset.id,
          "population_checksum" => @dataset.population_checksum,
          "parent_run_id" => @parent_run&.id
        }
      )
      begin
        MetricRun.transaction do
          snapshots = @dataset.metric_input_records.where(selected: true).order(:shadow_id).map do |record|
            calculate_snapshot(record, weights)
          end
          assign_dense_ranks(snapshots)
          validate_completion!(snapshots)
          @run.update!(status: "completed", completed_at: Time.current)
        end
      rescue => error
        @run.update!(status: "failed", failure_reason: error.message)
        raise
      end
      @run
    end

    def validate_configuration_subject!
      work_configuration = @configuration_version.end_with?("-work")
      if (@dataset.subject_type == "Philosopher" && work_configuration) || (@dataset.subject_type == "Work" && !work_configuration)
        raise ArgumentError, "Configuration #{@configuration_version} is not valid for #{@dataset.subject_type}"
      end
    end

    def default_configuration_version
      (@dataset.subject_type == "Philosopher") ? "2.1" : "2.0-work"
    end

    def default_calculator_identity
      (@dataset.subject_type == "Philosopher") ? "philosopher-v2" : "work-v2"
    end

    def default_signal_config
      if @dataset.subject_type == "Philosopher"
        {
          "suppressed_capacity_ids" => Canonicity::Philosopher::V2::SUPPRESSED_CAPACITY_IDS,
          "sources" => Canonicity::Philosopher::V2::SOURCES
        }
      else
        {"encyclopedia_sources" => Canonicity::Work::V2::ENCYCLOPEDIA_SOURCES}
      end
    end

    def configuration_fingerprint(weights, signal_config)
      canonical_weights = weights.sort.to_h.transform_values { |value| value&.to_f }
      Digest::SHA256.hexdigest(JSON.generate("weights" => canonical_weights, "signals" => signal_config))
    end

    def next_version(fingerprint)
      previous_completed = MetricRun.where(subject_type: @dataset.subject_type, status: "completed").order(major: :desc, minor: :desc, patch: :desc).first
      highest = MetricRun.where(subject_type: @dataset.subject_type).order(major: :desc, minor: :desc, patch: :desc).first
      @version_components = if highest.nil?
        [0, 7, 0]
      else
        bump = if previous_completed.nil?
          :patch
        elsif previous_completed.calculator_identity != @calculator_identity
          :major
        elsif previous_completed.configuration_version != @configuration_version || previous_completed.configuration_fingerprint != fingerprint
          :minor
        else
          :patch
        end
        components = [highest.major, highest.minor, highest.patch]
        case bump
        when :major
          [components[0] + 1, 0, 0]
        when :minor
          [components[0], components[1] + 1, 0]
        else
          [components[0], components[1], components[2] + 1]
        end
      end
      @version_components.join(".")
    end

    def calculate_snapshot(record, weights)
      inputs = (@dataset.subject_type == "Philosopher") ? CalculatorInput.philosopher(record) : CalculatorInput.work(record)
      dependencies = (@dataset.subject_type == "Work") ? CalculatorInput.work_dependencies(record) : {}
      result = Canonicity::Calculator.call(
        @calculator_identity,
        inputs: inputs,
        weights: weights,
        normalization_context: CalculatorInput.normalization_context(@dataset),
        dependency_inputs: dependencies
      )
      unless result[:measure].finite? && result[:normalized_measure].finite?
        raise ArgumentError, "Non-finite measure for shadow #{record.shadow_id}"
      end

      @run.metric_snapshots.create!(
        metric_input_record: record,
        shadow_id: record.shadow_id,
        shadow_type: record.shadow_type,
        calculated_at: Time.current,
        canonicity_weight_algorithm_version: @configuration_version,
        danker_version: "unknown",
        danker_file: "unknown",
        danker_score: record.input_payload["danker"],
        linkcount: record.input_payload["linkcount"],
        mention_count: record.input_payload["mention"],
        reference_work_flags: reference_flags(record).to_json,
        measure: result[:measure],
        calculation_context: result[:calculation_context].merge("normalized_measure" => result[:normalized_measure])
      )
    end

    def reference_flags(record)
      if @dataset.subject_type == "Philosopher"
        record.input_payload["sources"]
      else
        record.input_payload.slice(*Canonicity::Work::V2::ENCYCLOPEDIA_SOURCES, "philrecord", "philtopic", "genre")
      end
    end

    def assign_dense_ranks(snapshots)
      measures = snapshots.each_with_object({}) { |snapshot, result| result[snapshot.shadow_id] = snapshot.measure }
      ranks = Canonicity::DenseRank.for(measures)
      snapshots.each { |snapshot| snapshot.update!(measure_pos: ranks[snapshot.shadow_id]) }
    end

    def validate_completion!(snapshots)
      expected_ids = @dataset.selected_entity_ids.sort
      actual_ids = snapshots.map(&:shadow_id).sort
      raise ArgumentError, "Snapshot population is incomplete" unless actual_ids == expected_ids
      raise ArgumentError, "Duplicate snapshot population" unless actual_ids.uniq == actual_ids
      raise ArgumentError, "Non-finite snapshot measure" unless snapshots.all? { |snapshot| snapshot.measure.finite? }

      measures = snapshots.each_with_object({}) { |snapshot, result| result[snapshot.shadow_id] = snapshot.measure }
      expected_ranks = Canonicity::DenseRank.for(measures)
      snapshots.each do |snapshot|
        raise ArgumentError, "Dense rank verification failed" unless snapshot.measure_pos == expected_ranks[snapshot.shadow_id]
      end
    end
  end
end
