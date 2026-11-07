# frozen_string_literal: true

require 'thor'

module CorpusCli
  module Commands
    class Workflows < Thor
      namespace 'workflows'

      desc 'list', 'List all workflows by category'
      def list
        registry = CorpusCli.registry
        if registry.workflows.empty?
          puts "No workflows found."
          return
        end

        registry.by_category.each do |category, workflows|
          puts "\n  #{category.tr('_', ' ').upcase}"
          puts "  #{'=' * 40}"
          workflows.each do |wf|
            step_count = wf.steps.size
            aux_count = wf.auxiliary_steps.size
            aux_str = aux_count > 0 ? " + #{aux_count} auxiliary" : ""
            puts "    #{wf.name.ljust(30)} #{step_count} steps#{aux_str}"
          end
        end
        puts
      end

      desc 'show WORKFLOW', 'Show steps and status for a workflow'
      method_option :verbose, type: :boolean, default: false, desc: 'Show task commands'
      def show(workflow_name)
        registry = CorpusCli.registry
        wf = registry.find(workflow_name)

        unless wf
          puts "Unknown workflow: #{workflow_name}"
          puts "Available: #{registry.names.join(', ')}"
          return
        end

        tracker = CorpusCli.state_tracker
        completed = tracker.completed_steps(wf.name)

        puts
        puts "  #{wf.display_name}"
        puts "  #{wf.description}" if wf.description
        puts "  Category: #{wf.category}"
        puts

        puts "  Pipeline Steps:"
        wf.pipeline_order.each_with_index do |step, idx|
          marker = completed.include?(step.id) ? '[x]' : '[ ]'
          line = "    #{idx + 1}. #{marker} #{step.display_name} #{step.safety_label}"
          line += "  [~#{step.estimated_duration}]" if step.estimated_duration
          puts line

          if step.prerequisites.any?
            puts "       requires: #{step.prerequisites.join(', ')}"
          end

          puts "       task: #{step.task}" if options[:verbose]
        end

        if wf.auxiliary_steps.any?
          puts
          puts "  Auxiliary Steps (run independently):"
          wf.auxiliary_steps.each do |step|
            marker = completed.include?(step.id) ? '[x]' : '[ ]'
            puts "    #{marker} #{step.display_name} #{step.safety_label}"
          end
        end

        puts
        total = wf.steps.size
        done = wf.steps.count { |s| completed.include?(s.id) }
        puts "  Progress: #{done}/#{total} steps completed"
        puts
      end
    end
  end
end
