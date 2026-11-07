# frozen_string_literal: true

require_relative "state_tracker"

module CorpusCli
  class WorkflowRunner
    attr_reader :state_tracker

    def initialize(state_tracker: nil, dry_run: false, verbose: false, quiet: false)
      @state_tracker = state_tracker || StateTracker.new
      @dry_run = dry_run
      @verbose = verbose
      @quiet = quiet
    end

    def run_step(workflow, step, param_values: {}, skip_confirmation: false)
      command = step.build_command(param_values)

      unless skip_confirmation || step.read_only? || @dry_run
        return :skipped unless confirm_execution(step, command)
      end

      if @dry_run
        puts "[DRY RUN] Would execute: #{command}"
        return :dry_run
      end

      puts "Executing: #{command}" unless @quiet
      puts "  Safety: #{step.safety} #{step.safety_label}" if @verbose

      @state_tracker.record_start(workflow.name, step.id)
      start_time = Time.now

      success = system(command)
      duration = (Time.now - start_time).round(1)

      @state_tracker.record_finish(
        workflow.name, step.id,
        success: success,
        duration: duration
      )

      if success
        puts "  Completed in #{duration}s" unless @quiet
        :success
      else
        puts "  FAILED after #{duration}s (exit code: #{$?.exitstatus})" unless @quiet
        :failure
      end
    end

    def run_workflow(workflow, param_values: {}, skip_confirmation: false, halt_on_failure: true)
      completed = @state_tracker.completed_steps(workflow.name)
      pipeline = workflow.pipeline_order
      results = {}

      pipeline.each do |step|
        unmet = step.prerequisites.reject { |pre| completed.include?(pre) }
        if unmet.any?
          puts "  [blocked] #{step.display_name} (requires: #{unmet.join(", ")})" unless @quiet
          results[step.id] = :blocked
          completed.delete(step.id)
          next
        end

        prerequisites_unchanged = step.prerequisites.all? { |pre| results[pre] == :already_done }
        if completed.include?(step.id) && prerequisites_unchanged
          puts "  [skip] #{step.display_name} (already completed)" unless @quiet
          results[step.id] = :already_done
          next
        end

        result = if block_given?
          yield step
        else
          run_step(
            workflow, step,
            param_values: param_values.fetch(step.id, {}),
            skip_confirmation: skip_confirmation
          )
        end
        results[step.id] = result
        if result == :success || result == :dry_run
          completed.add(step.id)
        else
          completed.delete(step.id)
        end

        if result == :failure && halt_on_failure
          puts "\nPipeline halted due to failure at step '#{step.id}'." unless @quiet
          break
        end
      end

      results
    end

    def dry_run?
      @dry_run
    end

    private

    def confirm_execution(step, command)
      colour = case step.safety
      when "destructive" then "\e[31m"
      when "mutating" then "\e[33m"
      else "\e[0m"
      end
      reset = "\e[0m"

      puts "\n#{colour}#{step.safety.upcase}#{reset} operation: #{step.display_name}"
      puts "  Command: #{command}"
      puts "  #{step.description}" if step.description
      print "  Proceed? [y/N] "

      response = $stdin.gets&.strip&.downcase
      response == "y" || response == "yes"
    end
  end
end
