# frozen_string_literal: true

require 'tty-prompt'
require 'tty-box'
require_relative 'workflow_browser'

module CorpusCli
  module Tui
    class MainMenu
      def initialize
        @prompt = TTY::Prompt.new
      end

      def run
        loop do
          print_header
          choice = @prompt.select("What would you like to do?", cycle: true) do |menu|
            menu.choice 'Browse Workflows', :browse
            menu.choice 'View Status', :status
            menu.choice 'Run a Step', :run_step
            menu.choice 'Run a Workflow', :run_workflow
            menu.choice 'View Diagram', :diagram
            menu.choice 'Quit', :quit
          end

          case choice
          when :browse then WorkflowBrowser.new(@prompt).run
          when :status then show_status
          when :run_step then run_step_interactive
          when :run_workflow then run_workflow_interactive
          when :diagram then show_diagram
          when :quit then break
          end
        end
      end

      private

      def print_header
        puts
        box = TTY::Box.frame(
          width: 50,
          padding: [0, 1],
          title: { top_left: ' CorpusBuilder ' },
          border: :light
        ) { "Workflow Harness & Task Runner" }
        puts box
        puts
      end

      def show_status
        registry = CorpusCli.registry
        tracker = CorpusCli.state_tracker

        registry.workflows.each_value do |wf|
          completed = tracker.completed_steps(wf.name)
          total = wf.steps.size
          done = wf.steps.count { |s| completed.include?(s.id) }

          next_step = wf.next_step(completed)
          status = if total == 0
            "auxiliary only"
          elsif done == total
            "complete"
          elsif next_step
            "next: #{next_step.display_name}"
          else
            "#{done}/#{total}"
          end

          bar_width = 15
          filled = total > 0 ? (done.to_f / total * bar_width).round : 0
          bar = '#' * filled + '-' * (bar_width - filled)

          puts "  #{wf.display_name.ljust(40)} [#{bar}] #{done}/#{total}  #{status}"
        end
        puts
        @prompt.keypress("Press any key to continue...")
      end

      def run_step_interactive
        wf = select_workflow
        return unless wf

        step = select_step(wf)
        return unless step

        tracker = CorpusCli.state_tracker
        completed = tracker.completed_steps(wf.name)
        unmet = step.prerequisites.reject { |pre| completed.include?(pre) }

        if unmet.any?
          puts "\n  Warning: unmet prerequisites: #{unmet.join(', ')}"
          return unless @prompt.yes?("  Continue anyway?")
        end

        dry_run = @prompt.yes?("  Dry run?")

        require_relative 'execution_panel'
        ExecutionPanel.new(@prompt).run_step(wf, step, dry_run: dry_run)
      end

      def run_workflow_interactive
        wf = select_workflow
        return unless wf
        if wf.steps.empty?
          @prompt.say("  This workflow has no pipeline steps.")
          return
        end

        dry_run = @prompt.yes?("  Dry run?")

        require_relative 'execution_panel'
        ExecutionPanel.new(@prompt).run_workflow(wf, dry_run: dry_run)
      end

      def show_diagram
        wf = select_workflow
        return unless wf

        generator = DiagramGenerator.new(state_tracker: CorpusCli.state_tracker)
        puts
        puts generator.ascii(wf)
        puts
        @prompt.keypress("Press any key to continue...")
      end

      def select_workflow
        registry = CorpusCli.registry
        choices = registry.workflows.map do |name, wf|
          { name: "#{wf.display_name} (#{wf.steps.size} steps)", value: wf }
        end
        choices << { name: 'Back', value: nil }

        @prompt.select("Select workflow:", choices, cycle: true)
      end

      def select_step(wf)
        tracker = CorpusCli.state_tracker
        completed = tracker.completed_steps(wf.name)

        choices = wf.all_steps.map do |step|
          marker = completed.include?(step.id) ? '[x]' : '[ ]'
          { name: "#{marker} #{step.display_name} #{step.safety_label}", value: step }
        end
        choices << { name: 'Back', value: nil }

        @prompt.select("Select step:", choices, cycle: true, per_page: 15)
      end
    end
  end
end
