# frozen_string_literal: true

require 'thor'
require_relative 'workflow_registry'
require_relative 'workflow_runner'
require_relative 'state_tracker'
require_relative 'diagram_generator'
require_relative 'commands/workflows'
require_relative 'commands/run'
require_relative 'commands/status'
require_relative 'commands/diagram'

module CorpusCli
  class << self
    def registry
      @registry ||= WorkflowRegistry.new
    end

    def state_tracker
      @state_tracker ||= StateTracker.new
    end

    def reset!
      @registry = nil
      @state_tracker = nil
    end
  end

  class CLI < Thor
    desc 'workflows SUBCOMMAND', 'Manage workflows'
    subcommand 'workflows', Commands::Workflows

    desc 'exec SUBCOMMAND', 'Execute workflow steps'
    subcommand 'exec', Commands::Exec

    desc 'status SUBCOMMAND', 'View execution status'
    subcommand 'status', Commands::Status

    desc 'diagram SUBCOMMAND', 'Generate pipeline diagrams'
    subcommand 'diagram', Commands::Diagram

    desc 'tui', 'Launch interactive TUI'
    def tui
      require_relative 'tui/main_menu'
      Tui::MainMenu.new.run
    end

    desc 'man WORKFLOW [STEP]', 'Detailed help for a workflow or step'
    def man(workflow_name, step_id = nil)
      registry = CorpusCli.registry
      wf = registry.find(workflow_name)

      unless wf
        puts "Unknown workflow: #{workflow_name}"
        return
      end

      if step_id
        step = wf.find_step(step_id)
        unless step
          puts "Unknown step: #{step_id}"
          return
        end
        show_step_man(step)
      else
        show_workflow_man(wf)
      end
    end

    private

    def show_workflow_man(wf)
      puts
      puts "  #{wf.display_name}"
      puts "  #{'=' * wf.display_name.length}"
      puts
      puts "  #{wf.description}" if wf.description
      puts
      puts "  Category: #{wf.category}"
      puts "  Steps: #{wf.steps.size} pipeline + #{wf.auxiliary_steps.size} auxiliary"
      puts

      puts "  PIPELINE"
      wf.pipeline_order.each_with_index do |step, idx|
        puts "    #{idx + 1}. #{step.display_name}"
        puts "       Task: #{step.task}"
        puts "       Type: #{step.type} | Safety: #{step.safety}"
        puts "       Duration: ~#{step.estimated_duration}" if step.estimated_duration
        puts "       Requires: #{step.prerequisites.join(', ')}" if step.prerequisites.any?
        puts "       #{step.description}" if step.description
        puts
      end

      if wf.auxiliary_steps.any?
        puts "  AUXILIARY"
        wf.auxiliary_steps.each do |step|
          puts "    #{step.display_name}"
          puts "       Task: #{step.task}"
          puts "       #{step.description}" if step.description
          puts
        end
      end
    end

    def show_step_man(step)
      puts
      puts "  #{step.display_name}"
      puts "  #{'=' * step.display_name.length}"
      puts
      puts "  Task: #{step.task}"
      puts "  Type: #{step.type}"
      puts "  Safety: #{step.safety} #{step.safety_label}"
      puts "  Duration: ~#{step.estimated_duration}" if step.estimated_duration
      puts "  Prerequisites: #{step.prerequisites.join(', ')}" if step.prerequisites.any?
      puts
      puts "  #{step.description}" if step.description
      puts

      if step.params.any?
        puts "  PARAMETERS"
        step.params.each do |p|
          puts "    #{p.name} (#{p.type})"
          puts "      Default: #{p.default.inspect}"
          puts "      #{p.description}" if p.description
          puts
        end
      end

      if step.postconditions.any?
        puts "  POSTCONDITIONS"
        step.postconditions.each do |pc|
          puts "    #{pc['description']}"
          puts "      Check: #{pc['check']}"
        end
        puts
      end
    end
  end
end
