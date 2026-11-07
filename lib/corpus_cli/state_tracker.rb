# frozen_string_literal: true

require "json"
require "fileutils"
require "set"
require "time"

module CorpusCli
  class StateTracker
    attr_reader :log_path

    def initialize(log_path = nil)
      @log_path = log_path || File.expand_path("../../log/corpus_workflow.log", __dir__)
      FileUtils.mkdir_p(File.dirname(@log_path))
    end

    def record_start(workflow_name, step_id)
      append_event(
        event: "step_start",
        workflow: workflow_name,
        step: step_id,
        timestamp: Time.now.iso8601
      )
    end

    def record_finish(workflow_name, step_id, success:, duration: nil, output: nil)
      append_event(
        event: "step_finish",
        workflow: workflow_name,
        step: step_id,
        success: success,
        duration_seconds: duration,
        output_excerpt: output&.slice(0, 500),
        timestamp: Time.now.iso8601
      )
    end

    def record_reset(workflow_name)
      append_event(
        event: "workflow_reset",
        workflow: workflow_name,
        timestamp: Time.now.iso8601
      )
    end

    def completed_steps(workflow_name)
      events = load_events
      reset_idx = events.rindex { |e| e["event"] == "workflow_reset" && e["workflow"] == workflow_name }
      relevant = reset_idx ? events[(reset_idx + 1)..] : events

      completed = Set.new
      relevant.each do |e|
        next unless e["workflow"] == workflow_name
        case e["event"]
        when "step_start"
          completed.delete(e["step"])
        when "step_finish"
          e["success"] ? completed.add(e["step"]) : completed.delete(e["step"])
        end
      end
      completed
    end

    def last_run(workflow_name, step_id)
      events = load_events
      events.reverse.find { |e|
        e["workflow"] == workflow_name &&
          e["step"] == step_id &&
          e["event"] == "step_finish"
      }
    end

    def history(workflow_name = nil)
      events = load_events
      if workflow_name
        events.select { |e| e["workflow"] == workflow_name }
      else
        events
      end
    end

    def clear!
      File.write(@log_path, "")
    end

    private

    def append_event(data)
      File.open(@log_path, "a") do |f|
        f.puts(JSON.generate(data))
      end
    end

    def load_events
      return [] unless File.exist?(@log_path)

      File.readlines(@log_path).map do |line|
        line = line.strip
        next if line.empty?
        JSON.parse(line)
      end.compact
    end
  end
end
