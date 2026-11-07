module Canonicity
  class DatasetCapture
    def initialize(subject_type:, selected_entity_ids: nil, normalization_entity_ids: nil, input_run_id: nil, source_provenance: {})
      @subject_type = subject_type
      @selected_entity_ids = selected_entity_ids
      @normalization_entity_ids = normalization_entity_ids
      @input_run_id = input_run_id
      @source_provenance = source_provenance
    end

    def call
      MetricOperationLock.synchronize { capture }
    end

    private

    def capture
      selected_ids = normalization_ids = dependency = nil
      MetricInputDataset.transaction do
        selected_ids = canonical_ids(@selected_entity_ids || subject_class.pluck(:id))
        normalization_ids = canonical_ids(@normalization_entity_ids || subject_class.pluck(:id))
        raise CaptureError, "#{@subject_type} population is empty" if selected_ids.empty? || normalization_ids.empty?

        dependency = resolve_dependency if @subject_type == "Work"
        dataset = MetricInputDataset.create!(
          subject_type: @subject_type,
          status: "capturing",
          schema_version: "1.0",
          selected_entity_ids: selected_ids,
          normalization_entity_ids: normalization_ids,
          normalization_context: {},
          source_provenance: capture_provenance(dependency, (selected_ids + normalization_ids).uniq),
          input_run_id: dependency&.id,
          population_checksum: population_checksum(selected_ids, normalization_ids)
        )
        records = capture_records(dataset, selected_ids, normalization_ids, dependency)
        validate_coverage!(dataset, selected_ids, normalization_ids)
        dataset.update!(
          status: "ready",
          normalization_context: normalization_context(records),
          capture_completed_at: Time.current
        )
        dataset
      end
    rescue => error
      record_invalid_capture(selected_ids, normalization_ids, dependency, error)
      raise
    end

    def subject_class
      @subject_class ||= @subject_type.constantize
    rescue NameError
      raise CaptureError, "Unknown subject type: #{@subject_type}"
    end

    def canonical_ids(ids)
      Array(ids).map(&:to_i).uniq.sort
    end

    def population_checksum(selected_ids, normalization_ids)
      Digest::SHA256.hexdigest(JSON.generate(selected: selected_ids, normalization: normalization_ids))
    end

    def capture_provenance(dependency, union_ids)
      imports = SourceEvent.where(shadow_id: union_ids).select(:import_identity, :artifact_identity, :artifact_checksum).distinct.map do |event|
        {
          "import_identity" => event.import_identity,
          "artifact_identity" => event.artifact_identity,
          "artifact_checksum" => event.artifact_checksum
        }
      end
      @source_provenance.merge(
        "source_event_imports" => imports,
        "historical_provenance" => imports.empty? ? "unknown" : "only values without later source events",
        "input_run" => dependency && {"id" => dependency.id, "version" => dependency.version}
      )
    end

    def record_invalid_capture(selected_ids, normalization_ids, dependency, error)
      return if selected_ids.blank? || normalization_ids.blank?

      MetricInputDataset.create!(
        subject_type: @subject_type,
        status: "invalid",
        schema_version: "1.0",
        selected_entity_ids: selected_ids,
        normalization_entity_ids: normalization_ids,
        normalization_context: {},
        source_provenance: @source_provenance.merge("input_run" => dependency && {"id" => dependency.id, "version" => dependency.version}),
        input_run_id: dependency&.id,
        population_checksum: population_checksum(selected_ids, normalization_ids),
        failure_reason: error.message
      )
    end

    def resolve_dependency
      dependency = if @input_run_id
        MetricRun.find_by(id: @input_run_id)
      else
        MetricRun.where(subject_type: "Philosopher", status: "completed").order(id: :desc).first
      end
      unless dependency&.completed? && dependency.subject_type == "Philosopher"
        raise CaptureError, "A completed Philosopher run is required before capturing a Work dataset"
      end
      dependency
    end

    def capture_records(dataset, selected_ids, normalization_ids, dependency)
      union_ids = (selected_ids + normalization_ids).uniq.sort
      entities = subject_class.where(id: union_ids).order(:id).to_a
      found_ids = entities.map(&:id)
      missing_ids = union_ids - found_ids
      raise CaptureError, "Missing #{@subject_type} IDs: #{missing_ids.join(", ")}" if missing_ids.any?

      validate_provenance!(entities)
      validate_author_dependencies!(entities, dependency) if @subject_type == "Work"
      entities.map do |shadow|
        dataset.metric_input_records.create!(
          shadow_id: shadow.id,
          shadow_type: @subject_type,
          entity_id: shadow.entity_id,
          entity_label: entity_label(shadow),
          selected: selected_ids.include?(shadow.id),
          normalization: normalization_ids.include?(shadow.id),
          input_payload: input_payload(shadow, dependency)
        )
      end
    end

    def validate_provenance!(entities)
      latest_events = SourceEvent.where(shadow_id: entities.map(&:id)).order(:id).each_with_object({}) do |event, result|
        result[[event.shadow_id, event.attribute_name]] = event
      end
      entities.each do |shadow|
        attribute_values(shadow).each do |attribute, current_value|
          event = latest_events[[shadow.id, attribute]]
          next unless event && event.new_value != current_value

          raise CaptureError, "Source provenance mismatch for #{@subject_type} Q#{shadow.entity_id} #{attribute}: latest event has #{event.new_value.inspect}, captured #{current_value.inspect}"
        end
      end
    end

    def attribute_values(shadow)
      values = {"danker" => shadow.danker}
      if @subject_type == "Philosopher"
        (Canonicity::Philosopher::V2::SOURCES + %w[runes oxford2]).uniq.each { |source| values[source] = shadow.public_send(source) }
      else
        (Canonicity::Work::V2::ENCYCLOPEDIA_SOURCES + %w[philrecord philtopic genre]).each { |source| values[source] = shadow.public_send(source) }
      end
      values
    end

    def validate_author_dependencies!(works, dependency)
      problems = works.each_with_object([]) do |work, result|
        author_ids = Expression.where(work_id: work.id).order(:creator_id).pluck(:creator_id)
        snapshot_ids = dependency.metric_snapshots.where(shadow_id: author_ids).pluck(:shadow_id)
        missing_ids = author_ids - snapshot_ids
        result << "Q#{work.entity_id} (shadow IDs: #{missing_ids.join(", ")})" if missing_ids.any?
      end
      if problems.any?
        raise CaptureError, "Missing Philosopher dependency snapshots: #{problems.join("; ")}"
      end
    end

    def validate_coverage!(dataset, selected_ids, normalization_ids)
      records = dataset.metric_input_records.to_a
      expected_ids = (selected_ids + normalization_ids).uniq.sort
      raise CaptureError, "Input record coverage is incomplete" unless records.map(&:shadow_id).sort == expected_ids
      raise CaptureError, "Selected population coverage is incomplete" unless records.select(&:selected?).map(&:shadow_id).sort == selected_ids
      raise CaptureError, "Normalization population coverage is incomplete" unless records.select(&:normalization?).map(&:shadow_id).sort == normalization_ids
    end

    def entity_label(shadow)
      shadow.english.presence || "Q#{shadow.entity_id}"
    end

    def input_payload(shadow, dependency)
      payload = {
        "mention" => shadow.mention,
        "danker" => shadow.danker,
        "linkcount" => shadow.linkcount
      }
      if @subject_type == "Philosopher"
        payload["capacity_ids"] = shadow.capacities.pluck(:entity_id)
        payload["sources"] = (Canonicity::Philosopher::V2::SOURCES + %w[runes oxford2]).uniq.each_with_object({}) do |source, result|
          result[source] = shadow.public_send(source)
        end
      else
        (Canonicity::Work::V2::ENCYCLOPEDIA_SOURCES + %w[philrecord philtopic genre]).each do |source|
          payload[source] = shadow.public_send(source)
        end
        payload.merge!(author_payload(shadow, dependency))
      end
      payload
    end

    def author_payload(work, dependency)
      author_ids = Expression.where(work_id: work.id).order(:creator_id).pluck(:creator_id)
      snapshots = dependency.metric_snapshots.where(shadow_id: author_ids).index_by(&:shadow_id)
      {
        "author_ids" => author_ids,
        "author_snapshot_ids" => author_ids.map { |id| snapshots[id].id },
        "author_measures" => author_ids.map { |id| snapshots[id].measure }
      }
    end

    def normalization_context(records)
      Canonicity::NormalizationContext.for_records(records, @subject_type)
    end
  end
end
