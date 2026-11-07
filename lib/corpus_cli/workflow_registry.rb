# frozen_string_literal: true

require_relative 'workflow_definition'

module CorpusCli
  class WorkflowRegistry
    attr_reader :workflows

    def initialize(config_dir = nil)
      @config_dir = config_dir || File.expand_path('../../config/workflows', __dir__)
      @workflows = {}
      load_all!
    end

    def find(name)
      @workflows[name]
    end

    def names
      @workflows.keys.sort
    end

    def by_category
      grouped = {}
      @workflows.each_value do |wf|
        grouped[wf.category] ||= []
        grouped[wf.category] << wf
      end
      grouped.sort.to_h
    end

    def categories
      by_category.keys
    end

    def reload!
      @workflows.clear
      load_all!
    end

    private

    def load_all!
      Dir.glob(File.join(@config_dir, '*.yml')).sort.each do |path|
        wf = WorkflowDefinition.new(path)
        @workflows[wf.name] = wf
      end
    end
  end
end
