# frozen_string_literal: true

require "thor"

module CorpusCli
  module Commands
    class Exec < Thor
      namespace "exec"

      desc "workflow WORKFLOW", "Run an entire workflow pipeline"
      method_option :dry_run, type: :boolean, default: false, desc: "Show commands without executing"
      method_option :verbose, type: :boolean, default: false, desc: "Show detailed output"
      method_option :quiet, type: :boolean, default: false, desc: "Minimal output"
      method_option :yes, type: :boolean, default: false, aliases: "-y", desc: "Skip confirmation prompts"
      method_option :halt_on_failure, type: :boolean, default: true, desc: "Stop pipeline on failure"
      def workflow(workflow_name)
        registry = CorpusCli.registry
        wf = registry.find(workflow_name)

        unless wf
          puts "Unknown workflow: #{workflow_name}"
          puts "Available: #{registry.names.join(", ")}"
          exit 1
        end

        runner = WorkflowRunner.new(
          state_tracker: CorpusCli.state_tracker,
          dry_run: options[:dry_run],
          verbose: options[:verbose],
          quiet: options[:quiet]
        )

        puts "Running workflow: #{wf.display_name}"
        puts "Mode: #{options[:dry_run] ? "DRY RUN" : "LIVE"}"
        puts

        results = runner.run_workflow(
          wf,
          skip_confirmation: options[:yes],
          halt_on_failure: options[:halt_on_failure]
        )

        puts
        puts "Results:"
        results.each do |step_id, result|
          puts "  #{step_id}: #{result}"
        end
        exit 1 if results.values.any? { |result| [:failure, :blocked, :skipped].include?(result) }
      end

      desc "step WORKFLOW STEP", "Run a single step from a workflow"
      method_option :dry_run, type: :boolean, default: false, desc: "Show command without executing"
      method_option :verbose, type: :boolean, default: false, desc: "Show detailed output"
      method_option :quiet, type: :boolean, default: false, desc: "Minimal output"
      method_option :yes, type: :boolean, default: false, aliases: "-y", desc: "Skip confirmation prompts"
      def step(workflow_name, step_id)
        registry = CorpusCli.registry
        wf = registry.find(workflow_name)

        unless wf
          puts "Unknown workflow: #{workflow_name}"
          exit 1
        end

        step = wf.find_step(step_id)
        unless step
          puts "Unknown step: #{step_id}"
          puts "Available steps: #{wf.all_steps.map(&:id).join(", ")}"
          exit 1
        end

        tracker = CorpusCli.state_tracker
        completed = tracker.completed_steps(wf.name)

        unmet = step.prerequisites.reject { |pre| completed.include?(pre) }
        if unmet.any?
          puts "Warning: unmet prerequisites: #{unmet.join(", ")}"
          print "Continue anyway? [y/N] "
          return unless $stdin.gets&.strip&.downcase == "y"
        end

        runner = WorkflowRunner.new(
          state_tracker: tracker,
          dry_run: options[:dry_run],
          verbose: options[:verbose],
          quiet: options[:quiet]
        )

        param_values = collect_params(step) unless options[:dry_run]
        result = runner.run_step(wf, step, param_values: param_values || {}, skip_confirmation: options[:yes])
        exit 1 if [:failure, :blocked, :skipped].include?(result)
      end

      private

      def collect_params(step)
        return {} if step.params.empty?

        values = {}
        step.params.each do |param|
          if param.boolean?
            print "  #{param.prompt_label} [#{param.default ? "Y/n" : "y/N"}] "
            response = $stdin.gets.to_s.strip.downcase
            values[param.name] = if response.empty?
              param.default
            else
              response == "y" || response == "yes"
            end
          elsif param.enum? && param.options
            puts "  #{param.prompt_label}:"
            param.options.each_with_index { |opt, i| puts "    #{i + 1}. #{opt}" }
            print "  Choice [#{param.default}]: "
            response = $stdin.gets.to_s.strip
            values[param.name] = if response.empty?
              param.default
            elsif response.match?(/\A\d+\z/) && response.to_i.between?(1, param.options.size)
              param.options[response.to_i - 1]
            elsif param.options.include?(response)
              response
            else
              raise ArgumentError, "Invalid choice for #{param.name}: #{response}"
            end
          else
            print "  #{param.prompt_label} [#{param.default}]: "
            response = $stdin.gets.to_s.strip
            values[param.name] = response.empty? ? param.default : response
          end
        end
        values
      end
    end
  end
end
