# frozen_string_literal: true

require 'thor'

module CorpusCli
  module Commands
    class Status < Thor
      namespace 'status'

      desc 'show [WORKFLOW]', 'Show execution status for workflow(s)'
      def show(workflow_name = nil)
        registry = CorpusCli.registry
        tracker = CorpusCli.state_tracker

        if workflow_name
          wf = registry.find(workflow_name)
          unless wf
            puts "Unknown workflow: #{workflow_name}"
            return
          end
          show_workflow_status(wf, tracker)
        else
          registry.workflows.each_value do |wf|
            show_workflow_status(wf, tracker)
          end
        end
      end

      desc 'reset [WORKFLOW]', 'Clear execution history for a workflow'
      def reset(workflow_name = nil)
        tracker = CorpusCli.state_tracker

        if workflow_name
          tracker.record_reset(workflow_name)
          puts "Reset status for workflow: #{workflow_name}"
        else
          print "Reset ALL workflow history? [y/N] "
          return unless $stdin.gets&.strip&.downcase == 'y'
          tracker.clear!
          puts "All workflow history cleared."
        end
      end

      desc 'history [WORKFLOW]', 'Show execution history'
      method_option :limit, type: :numeric, default: 20, desc: 'Number of entries to show'
      def history(workflow_name = nil)
        tracker = CorpusCli.state_tracker
        events = tracker.history(workflow_name)

        if events.empty?
          puts "No history found."
          return
        end

        events.last(options[:limit]).each do |event|
          ts = event['timestamp']
          wf = event['workflow']
          step = event['step']
          type = event['event']

          case type
          when 'step_start'
            puts "  #{ts}  START   #{wf} / #{step}"
          when 'step_finish'
            status = event['success'] ? 'OK' : 'FAIL'
            dur = event['duration_seconds'] ? " (#{event['duration_seconds']}s)" : ''
            puts "  #{ts}  #{status.ljust(6)} #{wf} / #{step}#{dur}"
          when 'workflow_reset'
            puts "  #{ts}  RESET   #{wf}"
          end
        end
      end

      private

      def show_workflow_status(wf, tracker)
        completed = tracker.completed_steps(wf.name)
        total = wf.steps.size
        done = wf.steps.count { |s| completed.include?(s.id) }

        bar_width = 20
        filled = total > 0 ? (done.to_f / total * bar_width).round : 0
        bar = '#' * filled + '-' * (bar_width - filled)

        puts "  #{wf.display_name}"
        puts "    [#{bar}] #{done}/#{total} steps"

        next_step = wf.next_step(completed)
        if next_step
          puts "    Next: #{next_step.display_name}"
        elsif done == total
          puts "    Status: Complete"
        end
        puts
      end
    end
  end
end
