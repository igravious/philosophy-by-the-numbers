require "fileutils"

module Canonicity
  class MetricOperationLock
    LOCK_PATH_KEY = :canonicity_metric_operation_lock_path

    def self.synchronize(&block)
      new.synchronize(&block)
    end

    def initialize(lock_path = Rails.root.join("tmp", "metric_capture.lock"))
      @lock_path = lock_path
    end

    def synchronize
      return yield if Thread.current[LOCK_PATH_KEY] == @lock_path.to_s

      FileUtils.mkdir_p(File.dirname(@lock_path))
      File.open(@lock_path, "w") do |lock_file|
        lock_file.flock(File::LOCK_EX)
        Thread.current[LOCK_PATH_KEY] = @lock_path.to_s
        reconcile_interrupted_operations
        yield
      ensure
        Thread.current[LOCK_PATH_KEY] = nil
      end
    end

    private

    def reconcile_interrupted_operations
      MetricInputDataset.where(status: "capturing").find_each do |dataset|
        dataset.update!(status: "invalid", failure_reason: "interrupted")
      end
      MetricRun.where(status: "running").find_each do |run|
        run.update!(status: "failed", failure_reason: "interrupted")
      end
    end
  end
end
