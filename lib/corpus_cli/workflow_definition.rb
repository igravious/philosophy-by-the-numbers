# frozen_string_literal: true

require "yaml"
require_relative "workflow_step"

module CorpusCli
  class WorkflowDefinition
    attr_reader :name, :display_name, :description, :category,
      :steps, :auxiliary_steps

    def initialize(yaml_path)
      raw = YAML.load_file(yaml_path)
      wf = raw.fetch("workflow")

      @name = wf.fetch("name")
      @display_name = wf.fetch("display_name", @name.tr("_", " ").capitalize)
      @description = wf["description"]
      @category = wf.fetch("category", "uncategorised")

      @steps = (wf["steps"] || []).map { |s| WorkflowStep.new(s) }
      @auxiliary_steps = (wf["auxiliary_steps"] || []).map { |s| WorkflowStep.new(s) }

      validate_prerequisites!
    end

    def all_steps
      @steps + @auxiliary_steps
    end

    def find_step(step_id)
      all_steps.find { |s| s.id == step_id }
    end

    def pipeline_order
      sorted = []
      visited = {}
      temp = {}

      @steps.each do |step|
        topological_visit(step, visited, temp, sorted) unless visited[step.id]
      end

      sorted
    end

    def runnable_steps(completed_ids)
      @steps.select do |step|
        !completed_ids.include?(step.id) &&
          step.prerequisites.all? { |pre| completed_ids.include?(pre) }
      end
    end

    def next_step(completed_ids)
      runnable_steps(completed_ids).first
    end

    private

    def topological_visit(step, visited, temp, sorted)
      raise ArgumentError, "Circular dependency at step '#{step.id}'" if temp[step.id]

      return if visited[step.id]

      temp[step.id] = true

      step.prerequisites.each do |pre_id|
        pre_step = @steps.find { |s| s.id == pre_id }
        topological_visit(pre_step, visited, temp, sorted) if pre_step && !visited[pre_id]
      end

      temp.delete(step.id)
      visited[step.id] = true
      sorted << step
    end

    def validate_prerequisites!
      all_ids = all_steps.map(&:id)
      if all_ids.uniq.size != all_ids.size
        raise ArgumentError, "Duplicate step identity in workflow '#{@name}'"
      end

      pipeline_ids = @steps.map(&:id)
      all_steps.each do |step|
        step.prerequisites.each do |pre_id|
          unless all_ids.include?(pre_id)
            raise ArgumentError,
              "Step '#{step.id}' has unknown prerequisite '#{pre_id}' in workflow '#{@name}'"
          end
          if @steps.include?(step) && !pipeline_ids.include?(pre_id)
            raise ArgumentError,
              "Pipeline step '#{step.id}' depends on auxiliary step '#{pre_id}' in workflow '#{@name}'"
          end
        end
      end
    end
  end
end
