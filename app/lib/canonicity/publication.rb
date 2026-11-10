module Canonicity
  class Publication
    class Eligibility
      attr_reader :reasons, :dependency_warning

      def initialize(reasons:, dependency_warning:)
        @reasons = reasons
        @dependency_warning = dependency_warning
      end

      def eligible?
        reasons.empty?
      end

      def dependency_mismatch?
        dependency_warning.present?
      end
    end

    def initialize(run:, current_ids: nil, snapshots: nil)
      @run = run
      @current_ids = current_ids
      @snapshots = snapshots
    end

    def eligibility
      @eligibility ||= build_eligibility
    end

    def call
      MetricOperationLock.synchronize do
        ::Publication.transaction do
          @run.reload
          current_eligibility = build_eligibility
          unless current_eligibility.eligible?
            raise PublicationError, current_eligibility.reasons.join("; ")
          end

          MetricSnapshot.where(metric_run_id: @run.id).order(:shadow_id).each do |snapshot|
            subject_class.find(snapshot.shadow_id).update!(measure: snapshot.measure, measure_pos: snapshot.measure_pos)
          end
          ::Publication.create!(metric_run: @run, subject_type: @run.subject_type)
        end
      end
    end

    private

    def build_eligibility
      reasons = []
      reasons << "run is not completed" unless @run.completed?
      current_ids = @current_ids || subject_class.order(:id).pluck(:id)
      selected_ids = dataset.selected_entity_ids.map(&:to_i).sort
      normalization_ids = dataset.normalization_entity_ids.map(&:to_i).sort
      unless selected_ids == current_ids
        reasons << "selected population does not match current #{@run.subject_type} population"
      end
      unless normalization_ids == selected_ids && normalization_ids == current_ids
        reasons << "normalization population must equal selected IDs and current #{@run.subject_type} population"
      end

      snapshots = @snapshots || MetricSnapshot.where(metric_run_id: @run.id).to_a
      snapshot_ids = snapshots.map(&:shadow_id)
      unless snapshot_ids.sort == selected_ids && snapshot_ids.uniq.length == snapshot_ids.length
        reasons << "snapshot coverage does not match selected population"
      end
      finite = snapshots.all? { |snapshot| snapshot.measure&.finite? }
      reasons << "snapshot measures are not all finite" unless finite
      if finite
        measures = snapshots.each_with_object({}) { |snapshot, result| result[snapshot.shadow_id] = snapshot.measure }
        expected_ranks = Canonicity::DenseRank.for(measures)
        unless snapshots.all? { |snapshot| snapshot.measure_pos == expected_ranks[snapshot.shadow_id] }
          reasons << "dense ranks do not match snapshot measures"
        end
      end

      Eligibility.new(reasons: reasons, dependency_warning: dependency_warning)
    end

    def dependency_warning
      return unless @run.subject_type == "Work"

      dependency = dataset.input_run
      current = ::Publication.current_for("Philosopher")&.metric_run
      return if dependency && current && dependency.id == current.id

      dependency_description = dependency ? "Philosopher run #{dependency.version}" : "an unknown Philosopher run"
      current_description = current ? "currently published Philosopher run #{current.version}" : "no currently published Philosopher run"
      "Work run depends on #{dependency_description}, but the site uses #{current_description}."
    end

    def dataset
      @run.metric_input_dataset
    end

    def subject_class
      @run.subject_type.constantize
    end
  end
end
