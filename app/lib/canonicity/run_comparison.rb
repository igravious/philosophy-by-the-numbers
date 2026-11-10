module Canonicity
  class RunComparison
    class Report
      attr_reader :added_entities, :missing_entities, :changes, :unchanged_entity_count

      def initialize(data)
        @data = data
        @added_entities = data[:added_entities]
        @missing_entities = data[:missing_entities]
        @changes = data[:changes]
        @unchanged_entity_count = data[:unchanged_entity_count]
      end

      def to_h
        @data
      end

      def to_json(*)
        JSON.generate(to_h)
      end
    end

    def initialize(from_run:, to_run:)
      @from_run = from_run
      @to_run = to_run
    end

    def call
      unless @from_run.subject_type == @to_run.subject_type
        raise ArgumentError, "Metric run comparison requires the same subject type"
      end

      from_snapshots = snapshots_for(@from_run)
      to_snapshots = snapshots_for(@to_run)
      common_ids = from_snapshots.keys & to_snapshots.keys
      changes = common_ids.sort.map do |shadow_id|
        change_for(from_snapshots[shadow_id], to_snapshots[shadow_id])
      end.compact
      data = {
        from_run: run_identity(@from_run),
        to_run: run_identity(@to_run),
        added_entities: (to_snapshots.keys - from_snapshots.keys).sort,
        missing_entities: (from_snapshots.keys - to_snapshots.keys).sort,
        changes: changes,
        unchanged_entity_count: common_ids.length - changes.length,
        population: population_comparison,
        calculator: {
          from: @from_run.calculator_identity,
          to: @to_run.calculator_identity,
          changed: @from_run.calculator_identity != @to_run.calculator_identity
        },
        configuration: {
          from_version: @from_run.configuration_version,
          to_version: @to_run.configuration_version,
          from_fingerprint: @from_run.configuration_fingerprint,
          to_fingerprint: @to_run.configuration_fingerprint,
          changed: @from_run.configuration_version != @to_run.configuration_version || @from_run.configuration_fingerprint != @to_run.configuration_fingerprint
        }
      }
      Report.new(data)
    end

    private

    def snapshots_for(run)
      run.metric_snapshots.includes(:metric_input_record).index_by(&:shadow_id)
    end

    def change_for(from, to)
      return if from.measure == to.measure && from.measure_pos == to.measure_pos

      record = to.metric_input_record || from.metric_input_record
      {
        shadow_id: to.shadow_id,
        entity_id: record&.entity_id,
        label: record&.entity_label,
        from_measure: from.measure,
        to_measure: to.measure,
        measure_change: to.measure - from.measure,
        from_rank: from.measure_pos,
        to_rank: to.measure_pos,
        rank_change: (from.measure_pos && to.measure_pos) ? to.measure_pos - from.measure_pos : nil
      }
    end

    def population_comparison
      from_dataset = @from_run.metric_input_dataset
      to_dataset = @to_run.metric_input_dataset
      {
        selected: id_difference(from_dataset.selected_entity_ids, to_dataset.selected_entity_ids),
        normalization: id_difference(from_dataset.normalization_entity_ids, to_dataset.normalization_entity_ids).merge(
          context_changes: context_difference(from_dataset.normalization_context, to_dataset.normalization_context)
        ),
        from_checksum: from_dataset.population_checksum,
        to_checksum: to_dataset.population_checksum
      }
    end

    def id_difference(from_ids, to_ids)
      from = from_ids.map(&:to_i)
      to = to_ids.map(&:to_i)
      {added: (to - from).sort, missing: (from - to).sort}
    end

    def context_difference(from_context, to_context)
      (from_context.keys | to_context.keys).sort.each_with_object([]) do |field, result|
        next if from_context[field] == to_context[field]

        result << {field: field, from: from_context[field], to: to_context[field]}
      end
    end

    def run_identity(run)
      {
        id: run.id,
        subject_type: run.subject_type,
        version: run.version,
        status: run.status,
        dataset_id: run.metric_input_dataset_id
      }
    end
  end
end
