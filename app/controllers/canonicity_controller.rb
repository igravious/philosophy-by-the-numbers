class CanonicityController < ApplicationController
  def index
    @page_title = "Canonicity"
    @algorithm_version = params[:algorithm_version] || "2.1"
    @algorithm_versions = CanonicityWeights.select(:algorithm_version).distinct.order(:algorithm_version).pluck(:algorithm_version)
    @algorithm_version_options = @algorithm_versions.map { |version| [%w[2.0 2.1].include?(version) ? "#{version}-philosopher" : version, version] }
    @weights = CanonicityWeights.where(algorithm_version: @algorithm_version).order(:source_name)
    @signals = CanonicitySignal.where(algorithm_version: @algorithm_version).order(:name)
    @infrastructure_counts = {
      input_datasets: MetricInputDataset.count,
      metric_runs: MetricRun.count,
      source_events: SourceEvent.count,
      publications: Publication.count
    }
    @datasets = MetricInputDataset.order(id: :desc).limit(20)
    @source_events = SourceEvent.order(id: :desc).limit(20)
    @runs = MetricRun.order(id: :desc).limit(20)
    @publications = Publication.includes(:metric_run).order(id: :desc).limit(20)
    @current_publications = MetricRun::SUBJECT_TYPES.each_with_object({}) do |subject_type, result|
      result[subject_type] = Publication.current_for(subject_type)
    end
    population_ids = MetricRun::SUBJECT_TYPES.each_with_object({}) do |subject_type, result|
      result[subject_type] = subject_type.constantize.order(:id).pluck(:id)
    end
    snapshots_by_run = MetricSnapshot.where(metric_run_id: @runs.map(&:id)).group_by(&:metric_run_id)
    @publication_eligibilities = @runs.each_with_object({}) do |run, result|
      result[run.id] = Canonicity::Publication.new(
        run: run,
        current_ids: population_ids.fetch(run.subject_type),
        snapshots: snapshots_by_run[run.id] || []
      ).eligibility
    end
    compare_runs if params[:from_run_id].present? && params[:to_run_id].present?
  end

  def show
    @page_title = "Canonicity run"
    @run = MetricRun.find(params[:id])
    @snapshots = @run.metric_snapshots.order(:measure_pos, :shadow_id).page(params[:page]).per(100)
    @publication_eligibility = Canonicity::Publication.new(run: @run).eligibility
  end

  def replay
    @run = MetricRun.find(params[:id])
    @snapshots = @run.metric_snapshots.order(:measure_pos, :shadow_id).page(params[:page]).per(100)
    @publication_eligibility = Canonicity::Publication.new(run: @run).eligibility
    @report = Canonicity::Replay.new(run: @run).call
    render :show
  end

  def publish
    run = MetricRun.find(params[:id])
    publication = Canonicity::Publication.new(run: run).call
    redirect_to canonicity_run_path(run), notice: "Published #{run.subject_type} run #{run.version} as publication #{publication.id}."
  rescue Canonicity::PublicationError => error
    redirect_to canonicity_run_path(run), alert: error.message
  end

  private

  def compare_runs
    from_run = MetricRun.find(params[:from_run_id])
    to_run = MetricRun.find(params[:to_run_id])
    @comparison = Canonicity::RunComparison.new(from_run: from_run, to_run: to_run).call
  rescue ArgumentError => error
    @comparison_error = error.message
  end
end
