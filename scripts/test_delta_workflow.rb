#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test script for the Delta of Delta workflow
# Run this to validate the setup before processing real philosophical works

require 'fileutils'
require_relative '../lib/delta_analysis/delta_of_delta_processor'

def main
  puts "="*80
  puts "DELTA OF DELTA WORKFLOW - QUICK TEST"
  puts "="*80
  
  # Check if Saffron is available
  saffron_path = DeltaOfDeltaProcessor::SAFFRON_SCRIPT
  unless File.exist?(saffron_path)
    puts "❌ ERROR: Saffron not found at #{saffron_path}"
    puts "Please ensure Saffron is installed at ~/saffron-os"
    exit 1
  end
  
  puts "✅ Saffron found at: #{saffron_path}"
  
  # Create test works directory
  test_dir = File.join(__dir__, '..', '..', 'tmp', 'delta_test')
  works_dir = File.join(test_dir, 'test_works')
  output_dir = File.join(test_dir, 'output')
  
  FileUtils.mkdir_p(works_dir)
  FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
  
  puts "📁 Creating test works in: #{works_dir}"
  
  # Create three progressive philosophical works for testing
  works = [
    {
      filename: 'work_1_being.txt',
      content: <<~TEXT
        Philosophical Inquiry into Being
        
        What is being? This question has occupied philosophical minds since antiquity.
        Being represents the fundamental nature of existence itself.
        To exist is to have being, to possess reality in some form.
        
        The study of being forms the core of ontology and metaphysics.
        Being manifests in multiple ways: physical objects, mental states, abstract concepts.
        Each mode of being presents unique characteristics for philosophical analysis.
        
        The relationship between being and non-being creates paradoxes for understanding.
        How can we speak of what is not, when speaking requires being?
        These fundamental questions drive ontological inquiry.
      TEXT
    },
    {
      filename: 'work_2_being_knowledge.txt',
      content: <<~TEXT
        Philosophical Inquiry into Being and Knowledge
        
        What is being? This question has occupied philosophical minds since antiquity.
        Being represents the fundamental nature of existence itself.
        To exist is to have being, to possess reality in some form.
        
        But how do we know being? Knowledge of being requires both rational analysis and empirical investigation.
        Epistemology intersects with ontology in fundamental ways.
        The relationship between knower and known shapes our understanding of reality.
        
        The study of being forms the core of ontology and metaphysics.
        Being manifests in multiple ways: physical objects, mental states, abstract concepts.
        Each mode of being presents unique characteristics for philosophical analysis.
        
        Truth emerges through the correspondence between thought and reality.
        Knowledge claims about being must be justified through reason and experience.
        The criteria for knowledge determine what we can legitimately claim about existence.
        
        The relationship between being and non-being creates paradoxes for understanding.
        How can we speak of what is not, when speaking requires being?
        These fundamental questions drive ontological inquiry.
      TEXT
    },
    {
      filename: 'work_3_being_knowledge_ethics.txt',
      content: <<~TEXT
        Philosophical Inquiry into Being, Knowledge, and Ethics
        
        What is being? This question has occupied philosophical minds since antiquity.
        Being represents the fundamental nature of existence itself.
        To exist is to have being, to possess reality in some form.
        
        But how do we know being? Knowledge of being requires both rational analysis and empirical investigation.
        Epistemology intersects with ontology in fundamental ways.
        The relationship between knower and known shapes our understanding of reality.
        
        The ethical dimension emerges when we consider how we ought to live given our understanding of being.
        Moral philosophy depends fundamentally on our conception of human nature and reality.
        What constitutes the good life? How should rational beings act?
        
        The study of being forms the core of ontology and metaphysics.
        Being manifests in multiple ways: physical objects, mental states, abstract concepts.
        Each mode of being presents unique characteristics for philosophical analysis.
        
        Truth emerges through the correspondence between thought and reality.
        Knowledge claims about being must be justified through reason and experience.
        The criteria for knowledge determine what we can legitimately claim about existence.
        
        Virtue ethics emphasizes character development over rule-following or consequence calculation.
        The cultivation of wisdom, courage, temperance, and justice leads to human flourishing.
        Moral knowledge connects to being through our understanding of human nature and purpose.
        
        The relationship between being and non-being creates paradoxes for understanding.
        How can we speak of what is not, when speaking requires being?
        These fundamental questions drive ontological inquiry.
        
        Ethics, epistemology, and ontology form an integrated philosophical system.
        Changes in our understanding of being affect our approach to knowledge and morality.
        The philosophical life involves the harmonious development of all three domains.
      TEXT
    }
  ]
  
  # Write test works
  work_files = []
  works.each do |work|
    file_path = File.join(works_dir, work[:filename])
    File.write(file_path, work[:content])
    work_files << file_path
    puts "  ✏️  Created: #{work[:filename]} (#{work[:content].length} chars)"
  end
  
  puts "\n🚀 Starting Delta of Delta analysis..."
  puts "   Threshold: 0.05 (low threshold for testing)"
  puts "   Strategy: composite"
  puts "   Output: #{output_dir}"
  
  # Initialize and run the processor
  begin
    processor = DeltaOfDeltaProcessor.new(
      works: work_files,
      output_dir: output_dir,
      threshold: 0.05,
      diff_strategy: :composite
    )
    
    puts "\n" + "-"*60
    result = processor.process
    puts "-"*60
    
    puts "\n📊 TEST RESULTS:"
    puts "  Works processed: #{result[:summary][:total_works_processed]}"
    puts "  Iterations completed: #{result[:summary][:total_iterations]}"
    puts "  Convergence reached: #{result[:summary][:convergence_reached] ? '✅ YES' : '❌ NO'}"
    
    if processor.delta_of_deltas_history.any?
      puts "  Final delta of delta: #{processor.delta_of_deltas_history.last[:magnitude].round(4)}"
    end
    
    puts "\n📁 Output files generated:"
    Dir.glob(File.join(output_dir, '**', '*')).select { |f| File.file?(f) }.each do |f|
      puts "  #{f.sub(output_dir + '/', '')}"
    end
    
    puts "\n✅ Delta of Delta workflow test completed successfully!"
    puts "🎯 You can now run the full analysis on your philosophical works using:"
    puts "   bin/rake delta_analysis:process[_txt/**/*.txt,tmp/delta_output,0.1,composite]"
    
  rescue => e
    puts "\n❌ ERROR during test: #{e.message}"
    puts e.backtrace.first(5).join("\n")
    exit 1
  end
end

main if __FILE__ == $0