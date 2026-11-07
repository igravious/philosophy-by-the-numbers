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
  end

  def show
    @page_title = "Canonicity run"
    @run = MetricRun.find(params[:id])
    @snapshots = @run.metric_snapshots.order(:measure_pos, :shadow_id)
  end

  def replay
    @run = MetricRun.find(params[:id])
    @snapshots = @run.metric_snapshots.order(:measure_pos, :shadow_id)
    @report = Canonicity::Replay.new(run: @run).call
    render :show
  end
end
