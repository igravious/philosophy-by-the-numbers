# frozen_string_literal: true

require "tty-spinner"

module CorpusCli
  module Tui
    class ExecutionPanel
      def initialize(prompt)
        @prompt = prompt
      end

      def run_step(workflow, step, dry_run: false)
        param_values = collect_params(step)

        runner = WorkflowRunner.new(
          state_tracker: CorpusCli.state_tracker,
          dry_run: dry_run
        )

        if dry_run
          cmd = step.build_command(param_values)
          puts "\n  [DRY RUN] Would execute: #{cmd}"
          puts
        else
          confirm_and_run(workflow, step, runner, param_values)
        end
      end

      def run_workflow(workflow, dry_run: false)
        runner = WorkflowRunner.new(
          state_tracker: CorpusCli.state_tracker,
          dry_run: dry_run
        )

        if dry_run
          puts "\n  [DRY RUN] Workflow: #{workflow.display_name}"
          workflow.pipeline_order.each do |step|
            cmd = step.build_command
            puts "    #{step.display_name}: #{cmd}"
          end
          puts
        else
          puts "\n  Running: #{workflow.display_name}"
          runner.run_workflow(workflow) do |step|
            confirm_and_run(workflow, step, runner, collect_params(step))
          end
        end

        @prompt.keypress("\nPress any key to continue...")
      end

      private

      def collect_params(step)
        return {} if step.params.empty?

        values = {}
        step.params.each do |param|
          values[param.name] = if param.boolean?
            @prompt.yes?("  #{param.prompt_label}?", default: param.default)
          elsif param.enum? && param.options
            @prompt.select(
              "  #{param.prompt_label}:",
              param.options,
              default: param.default
            )
          else
            @prompt.ask(
              "  #{param.prompt_label}:",
              default: param.default&.to_s
            )
          end
        end
        values
      end

      def confirm_and_run(workflow, step, runner, param_values)
        cmd = step.build_command(param_values)

        unless step.read_only?
          safety_msg = case step.safety
          when "destructive" then "\e[31mDESTRUCTIVE\e[0m"
          when "mutating" then "\e[33mMUTATING\e[0m"
          else step.safety
          end

          puts "\n  #{safety_msg}: #{step.display_name}"
          puts "  Command: #{cmd}"
          return :skipped unless @prompt.yes?("  Execute?")
        end

        spinner = TTY::Spinner.new(
          "  [:spinner] #{step.display_name}...",
          format: :dots
        )
        spinner.auto_spin

        result = runner.run_step(workflow, step, param_values: param_values, skip_confirmation: true)
        if result == :success
          spinner.success
          :success
        else
          spinner.error
          :failure
        end
      ensure
        spinner&.stop
      end
    end
  end
end
