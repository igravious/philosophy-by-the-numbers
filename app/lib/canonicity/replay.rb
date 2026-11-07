module Canonicity
  class Replay
    class Report
      attr_reader :matches, :added_entities, :missing_entities, :mismatches, :normalization_mismatches

      def initialize(matches:, added_entities:, missing_entities:, mismatches:, normalization_mismatches:)
        @matches = matches
        @added_entities = added_entities
        @missing_entities = missing_entities
        @mismatches = mismatches
        @normalization_mismatches = normalization_mismatches
      end

      def matches?
        @matches
      end

      def to_h
        {
          matches: matches,
          added_entities: added_entities,
          missing_entities: missing_entities,
          mismatches: mismatches,
          normalization_mismatches: normalization_mismatches
        }
      end

      def to_json(*)
        JSON.generate(to_h)
      end
    end

    def initialize(run:)
      @run = run
      @dataset = run.metric_input_dataset
    end

    def call
      raise ArgumentError, "Replay requires a completed run" unless @run.completed?

      stored = MetricSnapshot.where(metric_run_id: @run.id).index_by(&:shadow_id)
      expected = replayed_snapshots
      selected_ids = @dataset.selected_entity_ids.sort
      missing = selected_ids - stored.keys
      added = stored.keys - selected_ids
      mismatches = expected.each_with_object([]) do |(shadow_id, replayed), result|
        snapshot = stored[shadow_id]
        next unless snapshot
        next if snapshot.measure == replayed[:measure] && snapshot.measure_pos == replayed[:measure_pos]

        result << {
          shadow_id: shadow_id,
          stored_measure: snapshot.measure,
          replayed_measure: replayed[:measure],
          stored_rank: snapshot.measure_pos,
          replayed_rank: replayed[:measure_pos]
        }
      end
      normalization_mismatches = normalization_mismatches()
      Report.new(
        matches: missing.empty? && added.empty? && mismatches.empty? && normalization_mismatches.empty?,
        added_entities: added,
        missing_entities: missing,
        mismatches: mismatches,
        normalization_mismatches: normalization_mismatches
      )
    end

    private

    def replayed_snapshots
      measures = @dataset.metric_input_records.where(selected: true).order(:shadow_id).each_with_object({}) do |record, result|
        inputs = (@dataset.subject_type == "Philosopher") ? CalculatorInput.philosopher(record) : CalculatorInput.work(record)
        dependencies = (@dataset.subject_type == "Work") ? CalculatorInput.work_dependencies(record) : {}
        calculation = Canonicity::Calculator.call(
          @run.calculator_identity,
          inputs: inputs,
          weights: @run.weights_config,
          normalization_context: CalculatorInput.normalization_context(@dataset),
          dependency_inputs: dependencies
        )
        result[record.shadow_id] = {measure: calculation[:measure], normalized_measure: calculation[:normalized_measure]}
      end
      dense_ranks(measures)
    end

    def dense_ranks(measures)
      ranks = Canonicity::DenseRank.for(measures.transform_values { |result| result[:measure] })
      measures.each { |shadow_id, result| result[:measure_pos] = ranks[shadow_id] }
      measures
    end

    def normalization_mismatches
      expected = Canonicity::NormalizationContext.for_records(@dataset.metric_input_records.to_a, @dataset.subject_type)
      stored = @dataset.normalization_context
      (expected.keys | stored.keys).each_with_object([]) do |field, result|
        next if expected[field] == stored[field]

        result << {field: field, stored: stored[field], replayed: expected[field]}
      end
    end
  end
end
