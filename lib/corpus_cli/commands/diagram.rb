# frozen_string_literal: true

require 'thor'

module CorpusCli
  module Commands
    class Diagram < Thor
      namespace 'diagram'

      desc 'ascii WORKFLOW', 'Display ASCII pipeline diagram in terminal'
      def ascii(workflow_name)
        registry = CorpusCli.registry
        wf = registry.find(workflow_name)

        unless wf
          puts "Unknown workflow: #{workflow_name}"
          return
        end

        tracker = CorpusCli.state_tracker
        completed = tracker.completed_steps(wf.name)
        generator = DiagramGenerator.new(state_tracker: tracker)

        puts generator.ascii(wf, completed)
      end

      desc 'mermaid [WORKFLOW]', 'Generate Mermaid diagram documentation'
      method_option :all, type: :boolean, default: false, desc: 'Generate all workflow docs'
      method_option :output_dir, type: :string, desc: 'Output directory for docs'
      def mermaid(workflow_name = nil)
        registry = CorpusCli.registry
        generator = DiagramGenerator.new

        if options[:all] || workflow_name.nil?
          output_dir = options[:output_dir] || File.expand_path('../../docs/workflows', __dir__)
          generator.generate_all_docs(registry, output_dir)
          puts "Generated Mermaid docs in #{output_dir}/"
          registry.workflows.each_value do |wf|
            puts "  #{wf.name}.md"
          end
        else
          wf = registry.find(workflow_name)
          unless wf
            puts "Unknown workflow: #{workflow_name}"
            return
          end
          puts generator.mermaid_doc(wf)
        end
      end
    end
  end
end
