module CanonicityRunHelpers
  def create_completed_metric_run(subject_type:, shadows:, measures:, version: "0.7.0", input_run: nil, selected_entity_ids: nil, normalization_entity_ids: nil)
    selected_ids = (selected_entity_ids || shadows.map(&:id)).map(&:to_i).sort
    normalization_ids = (normalization_entity_ids || shadows.map(&:id)).map(&:to_i).sort
    dataset = MetricInputDataset.create!(
      subject_type: subject_type,
      status: "ready",
      schema_version: "1.0",
      selected_entity_ids: selected_ids,
      normalization_entity_ids: normalization_ids,
      normalization_context: {"max_mention" => 100.0, "max_rank" => 1.0, "min_rank" => 0.1},
      source_provenance: {},
      input_run: input_run,
      population_checksum: "population-#{subject_type}-#{version}",
      capture_completed_at: Time.current
    )
    components = version.split(".").map(&:to_i)
    run = MetricRun.create!(
      subject_type: subject_type,
      version: version,
      major: components[0],
      minor: components[1],
      patch: components[2],
      metric_input_dataset: dataset,
      calculator_identity: (subject_type == "Philosopher") ? "philosopher-v2" : "work-v2",
      configuration_version: (subject_type == "Philosopher") ? "2.1" : "2.0-work",
      configuration_fingerprint: "configuration-#{subject_type}-#{version}",
      status: "running",
      started_at: Time.current,
      weights_config: {},
      signal_config: {},
      source_provenance: {}
    )
    shadows.each do |shadow|
      record = dataset.metric_input_records.create!(
        shadow_id: shadow.id,
        shadow_type: subject_type,
        entity_id: shadow.entity_id,
        entity_label: "Q#{shadow.entity_id}",
        selected: selected_ids.include?(shadow.id),
        normalization: normalization_ids.include?(shadow.id),
        input_payload: {"shadow_id" => shadow.id}
      )
      next unless selected_ids.include?(shadow.id)

      run.metric_snapshots.create!(
        metric_input_record: record,
        shadow_id: shadow.id,
        shadow_type: subject_type,
        calculated_at: Time.current,
        canonicity_weight_algorithm_version: run.configuration_version,
        danker_version: "unknown",
        danker_file: "unknown",
        reference_work_flags: "{}",
        measure: measures.fetch(shadow.id),
        calculation_context: {"normalized_measure" => measures.fetch(shadow.id)}
      )
    end
    ranks = Canonicity::DenseRank.for(measures)
    run.metric_snapshots.each { |snapshot| snapshot.update!(measure_pos: ranks.fetch(snapshot.shadow_id)) }
    run.update!(status: "completed", completed_at: Time.current)
    run
  end
end
