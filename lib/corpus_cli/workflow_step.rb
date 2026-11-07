# frozen_string_literal: true

require "shellwords"

module CorpusCli
  class StepParam
    attr_reader :name, :type, :default, :description, :options

    def initialize(hash)
      @name = hash.fetch("name")
      @type = hash.fetch("type", "string")
      @default = hash["default"]
      @description = hash["description"]
      @options = hash["options"]
    end

    def boolean?
      @type == "boolean"
    end

    def enum?
      @type == "enum"
    end

    def prompt_label
      label = @name.tr("_", " ").capitalize
      label += " (#{@description})" if @description
      label
    end
  end

  class WorkflowStep
    VALID_TYPES = %w[rake rails_runner shell].freeze
    VALID_SAFETY = %w[read_only mutating destructive].freeze

    attr_reader :id, :task, :type, :display_name, :description, :safety,
      :params, :estimated_duration, :prerequisites, :postconditions

    def initialize(hash)
      @id = hash.fetch("id")
      @task = hash.fetch("task")
      @type = hash.fetch("type", "rake")
      @display_name = hash.fetch("display_name", @id.tr("_", " ").capitalize)
      @description = hash["description"]
      @safety = hash.fetch("safety", "mutating")
      @params = (hash["params"] || []).map { |p| StepParam.new(p) }
      @estimated_duration = hash["estimated_duration"]
      @prerequisites = hash.fetch("prerequisites", [])
      @postconditions = hash["postconditions"] || []

      validate!
    end

    def build_command(param_values = {})
      case @type
      when "rake"
        build_rake_command(param_values)
      when "rails_runner"
        build_runner_command(param_values)
      when "shell"
        @task
      end
    end

    def read_only?
      @safety == "read_only"
    end

    def mutating?
      @safety == "mutating"
    end

    def destructive?
      @safety == "destructive"
    end

    def safety_label
      case @safety
      when "read_only" then "(R)"
      when "mutating" then "(M)"
      when "destructive" then "(D)"
      end
    end

    def safety_colour
      case @safety
      when "read_only" then :green
      when "mutating" then :yellow
      when "destructive" then :red
      end
    end

    private

    def build_rake_command(param_values = {})
      task = @task.dup
      values = ordered_param_values(param_values)
      unless values.empty?
        args = values.map { |value| value.to_s.gsub(/[\\,]/) { |character| "\\#{character}" } }
        task += "[#{args.join(",")}]"
      end
      Shellwords.join(["bin/rake", task])
    end

    def build_runner_command(param_values = {})
      Shellwords.join(["bin/rails", "runner", @task] + ordered_param_values(param_values).map(&:to_s))
    end

    def ordered_param_values(param_values)
      values = @params.map do |param|
        if param_values.key?(param.name)
          param_values[param.name]
        elsif param_values.key?(param.name.to_sym)
          param_values[param.name.to_sym]
        else
          param.default
        end
      end
      values.pop while !values.empty? && values.last.nil?
      values
    end

    def validate!
      raise ArgumentError, "Invalid step type: #{@type}" unless VALID_TYPES.include?(@type)
      raise ArgumentError, "Invalid safety level: #{@safety}" unless VALID_SAFETY.include?(@safety)
    end
  end
end
