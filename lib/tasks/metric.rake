namespace :metric do
  desc "Capture an immutable canonicity input dataset"
  task :capture, [:subject_type, :input_run_id, :selected_entity_ids, :normalization_entity_ids] => :environment do |_task, args|
    selected_ids = args[:selected_entity_ids]&.split("|")
    normalization_ids = args[:normalization_entity_ids]&.split("|")
    dataset = Canonicity::DatasetCapture.new(
      subject_type: args[:subject_type],
      input_run_id: args[:input_run_id].presence,
      selected_entity_ids: selected_ids,
      normalization_entity_ids: normalization_ids
    ).call
    puts "Captured #{dataset.subject_type} dataset #{dataset.id}: #{dataset.status}, #{dataset.selected_entity_ids.length} selected, #{dataset.normalization_entity_ids.length} normalization"
  end

  desc "Atomically import a Danker CSV or TSV file with source events"
  task :import_danker, [:file_path, :subject_type, :source_version] => :environment do |_task, args|
    subject_type = args[:subject_type].presence || "Philosopher"
    import_identity = Canonicity::DankerImport.new(
      args[:file_path],
      subject_type: subject_type,
      source_version: args[:source_version].presence
    ).call
    puts "Imported #{subject_type} Danker values with import identity #{import_identity}"
  end

  desc "Atomically import Work reference flags from JSON with source events"
  task :import_work_flags, [:file_path] => :environment do |_task, args|
    import_identity = Canonicity::WorkFlagImport.new(args[:file_path]).call
    puts "Imported Work reference flags with import identity #{import_identity}"
  end

  desc "Calculate a controlled metric run over a ready dataset"
  task :calculate, [:dataset_id, :configuration_version, :parent_run_id] => :environment do |_task, args|
    dataset = MetricInputDataset.find(args[:dataset_id])
    parent_run = MetricRun.find_by(id: args[:parent_run_id]) if args[:parent_run_id].present?
    run = Canonicity::MetricRunCalculator.new(
      dataset: dataset,
      configuration_version: args[:configuration_version].presence,
      parent_run: parent_run
    ).call
    puts "Completed #{run.subject_type} run #{run.version} (ID #{run.id}) with #{run.metric_snapshots.count} snapshots"
  end

  desc "List metric runs"
  task runs: :environment do
    MetricRun.order(:subject_type, :major, :minor, :patch).each do |run|
      puts "#{run.subject_type} #{run.version} ID=#{run.id} status=#{run.status} dataset=#{run.metric_input_dataset_id} configuration=#{run.configuration_version}"
    end
  end

  desc "Show a metric run and its snapshots"
  task :show, [:subject_type, :version] => :environment do |_task, args|
    run = MetricRun.find_by!(subject_type: args[:subject_type], version: args[:version])
    puts JSON.pretty_generate(run.attributes.slice("id", "subject_type", "version", "status", "metric_input_dataset_id", "calculator_identity", "configuration_version", "configuration_fingerprint", "failure_reason"))
    puts JSON.pretty_generate(run.metric_snapshots.order(:measure_pos, :shadow_id).map { |snapshot| snapshot.attributes.slice("shadow_id", "measure", "measure_pos", "calculation_context") })
  end

  desc "Recalculate from the same dataset with an explicit configuration"
  task :recalculate, [:subject_type, :version, :configuration_version] => :environment do |_task, args|
    parent_run = MetricRun.find_by!(subject_type: args[:subject_type], version: args[:version])
    run = Canonicity::MetricRunCalculator.new(
      dataset: parent_run.metric_input_dataset,
      configuration_version: args[:configuration_version],
      parent_run: parent_run
    ).call
    puts "Completed #{run.subject_type} run #{run.version} (ID #{run.id}) from dataset #{run.metric_input_dataset_id}"
  end

  desc "Replay a completed run without writing anything"
  task :replay, [:subject_type, :version] => :environment do |_task, args|
    run = MetricRun.find_by!(subject_type: args[:subject_type], version: args[:version])
    report = Canonicity::Replay.new(run: run).call
    puts report.to_json
    raise "Replay mismatches detected" unless report.matches?
  end

  desc "Compare measures, ranks, populations, and configuration between two runs"
  task :compare, [:subject_type, :from_version, :to_version] => :environment do |_task, args|
    from_run = MetricRun.find_by!(subject_type: args[:subject_type], version: args[:from_version])
    to_run = MetricRun.find_by!(subject_type: args[:subject_type], version: args[:to_version])
    report = Canonicity::RunComparison.new(from_run: from_run, to_run: to_run).call
    puts JSON.pretty_generate(report.to_h)
  end

  desc "Publish an eligible completed run to current display values"
  task :publish, [:subject_type, :version] => :environment do |_task, args|
    run = MetricRun.find_by!(subject_type: args[:subject_type], version: args[:version])
    service = Canonicity::Publication.new(run: run)
    warning = service.eligibility.dependency_warning
    puts "WARNING: #{warning}" if warning
    publication = service.call
    puts "Published #{run.subject_type} run #{run.version} (ID #{run.id}) as publication #{publication.id}"
  end
end
