# frozen_string_literal: true

require 'tty-table'
require_relative 'step_inspector'

module CorpusCli
  module Tui
    class WorkflowBrowser
      def initialize(prompt)
        @prompt = prompt
      end

      def run
        loop do
          wf = select_workflow
          break unless wf
          browse_workflow(wf)
        end
      end

      private

      def select_workflow
        registry = CorpusCli.registry
        tracker = CorpusCli.state_tracker

        choices = []
        registry.by_category.each do |category, workflows|
          choices << { name: "--- #{category.tr('_', ' ').upcase} ---", disabled: '' }
          workflows.each do |wf|
            completed = tracker.completed_steps(wf.name)
            total = wf.steps.size
            done = wf.steps.count { |s| completed.include?(s.id) }
            progress = total > 0 ? " (#{done}/#{total})" : " (auxiliary)"
            choices << { name: "  #{wf.display_name}#{progress}", value: wf }
          end
        end
        choices << { name: 'Back', value: nil }

        @prompt.select("Browse workflows:", choices, cycle: true, per_page: 20)
      end

      def browse_workflow(wf)
        tracker = CorpusCli.state_tracker
        completed = tracker.completed_steps(wf.name)

        loop do
          puts
          puts "  #{wf.display_name}"
          puts "  #{wf.description}" if wf.description
          puts

          if wf.steps.any?
            rows = wf.pipeline_order.map.with_index do |step, idx|
              marker = completed.include?(step.id) ? 'x' : ' '
              prereqs = step.prerequisites.any? ? step.prerequisites.join(', ') : '-'
              [idx + 1, marker, step.display_name, step.safety, prereqs, step.estimated_duration || '-']
            end

            table = TTY::Table.new(
              header: ['#', ' ', 'Step', 'Safety', 'Requires', 'Duration'],
              rows: rows
            )
            puts table.render(:unicode, padding: [0, 1])
          end

          if wf.auxiliary_steps.any?
            puts
            puts "  Auxiliary:"
            wf.auxiliary_steps.each do |step|
              marker = completed.include?(step.id) ? '[x]' : '[ ]'
              puts "    #{marker} #{step.display_name} #{step.safety_label}"
            end
          end

          puts
          choice = @prompt.select("Action:", cycle: true) do |menu|
            menu.choice 'Inspect a step', :inspect
            menu.choice 'Back', :back
          end

          case choice
          when :inspect
            step = select_step_from(wf, completed)
            StepInspector.new(@prompt).show(wf, step) if step
          when :back
            break
          end
        end
      end

      def select_step_from(wf, completed)
        choices = wf.all_steps.map do |step|
          marker = completed.include?(step.id) ? '[x]' : '[ ]'
          { name: "#{marker} #{step.display_name}", value: step }
        end
        choices << { name: 'Cancel', value: nil }

        @prompt.select("Select step to inspect:", choices, cycle: true, per_page: 15)
      end
    end
  end
end
