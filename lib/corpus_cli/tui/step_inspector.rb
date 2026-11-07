# frozen_string_literal: true

require 'tty-box'

module CorpusCli
  module Tui
    class StepInspector
      def initialize(prompt)
        @prompt = prompt
      end

      def show(workflow, step)
        tracker = CorpusCli.state_tracker
        completed = tracker.completed_steps(workflow.name)
        last_run = tracker.last_run(workflow.name, step.id)

        puts
        box = TTY::Box.frame(
          width: 60,
          padding: [0, 1],
          title: { top_left: " #{step.display_name} " },
          border: :light
        ) do
          lines = []
          lines << "Task:     #{step.task}"
          lines << "Type:     #{step.type}"
          lines << "Safety:   #{step.safety} #{step.safety_label}"
          lines << "Status:   #{completed.include?(step.id) ? 'Completed' : 'Pending'}"
          lines << "Duration: ~#{step.estimated_duration}" if step.estimated_duration
          lines << ""
          lines << step.description if step.description

          if step.prerequisites.any?
            lines << ""
            lines << "Prerequisites:"
            step.prerequisites.each do |pre_id|
              pre_status = completed.include?(pre_id) ? 'done' : 'pending'
              lines << "  #{pre_id} (#{pre_status})"
            end
          end

          if step.params.any?
            lines << ""
            lines << "Parameters:"
            step.params.each do |p|
              lines << "  #{p.name} (#{p.type}, default: #{p.default.inspect})"
            end
          end

          if last_run
            lines << ""
            lines << "Last Run:"
            lines << "  Time: #{last_run['timestamp']}"
            lines << "  Result: #{last_run['success'] ? 'Success' : 'Failed'}"
            lines << "  Duration: #{last_run['duration_seconds']}s" if last_run['duration_seconds']
          end

          if step.postconditions.any?
            lines << ""
            lines << "Postconditions:"
            step.postconditions.each do |pc|
              lines << "  #{pc['description']}"
            end
          end

          lines.join("\n")
        end
        puts box

        puts
        cmd = step.build_command
        puts "  Command: #{cmd}"
        puts

        @prompt.keypress("Press any key to continue...")
      end
    end
  end
end
