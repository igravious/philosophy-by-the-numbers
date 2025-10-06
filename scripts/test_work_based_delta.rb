#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for Work-Based Delta of Delta Analysis
# This demonstrates using philosophical works from the Shadow table

require_relative '../config/environment'
require_relative '../lib/delta_analysis/work_based_delta_processor'

def main
  puts "="*80
  puts "WORK-BASED DELTA OF DELTA ANALYSIS - TEST"
  puts "="*80
  
  # Check database connectivity
  begin
    work_count = Work.count
    work_with_files_count = Work.joins(text: :fyle)
                               .where.not(obsolete: true)
                               .where.not(fyles: { local_file: nil })
                               .count
                               
    puts "✅ Database connected"
    puts "📊 Total works in database: #{work_count}"
    puts "📄 Works with text files: #{work_with_files_count}"
    
    if work_with_files_count == 0
      puts "\n❌ No works with text files found!"
      puts "💡 Try running: bin/rake shadow:work:populate[works1]"
      puts "💡 Then run: bin/rake shadow:work:connect"
      exit 1
    end
    
  rescue => e
    puts "❌ Database error: #{e.message}"
    exit 1
  end
  
  # Show available strategies
  puts "\n📋 Available selection strategies:"
  puts "  • canonicity - Order by canonicity measure (if available)"
  puts "  • linkcount - Order by Wikidata link count"
  puts "  • mixed - Combine canonicity and linkcount"
  puts "  • random - Random selection"
  puts "  • recent - Most recently added works"
  
  # Test different strategies with small samples
  strategies_to_test = [:linkcount, :canonicity, :mixed]
  
  strategies_to_test.each do |strategy|
    puts "\n" + "-"*60
    puts "Testing #{strategy.upcase} strategy"
    puts "-"*60
    
    test_dir = File.join(__dir__, '..', 'tmp', "delta_test_#{strategy}")
    FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
    
    begin
      processor = case strategy
      when :canonicity
        WorkBasedDeltaProcessor.by_canonicity(
          max_works: 5,
          output_dir: test_dir,
          threshold: 0.1,
          diff_strategy: :term_weight
        )
      when :linkcount
        WorkBasedDeltaProcessor.by_linkcount(
          max_works: 5,
          output_dir: test_dir,
          threshold: 0.1,
          diff_strategy: :term_weight
        )
      when :mixed
        WorkBasedDeltaProcessor.mixed_ranking(
          max_works: 5,
          output_dir: test_dir,
          threshold: 0.1,
          diff_strategy: :term_weight
        )
      end
      
      if processor.works.length < 2
        puts "⚠️  Only #{processor.works.length} works with files found for #{strategy}, skipping..."
        next
      end
      
      puts "🚀 Running analysis with #{processor.works.length} works..."
      
      # For testing, we'll just show what would be processed without running Saffron
      puts "📁 Works selected:"
      processor.instance_variable_get(:@work_metadata).each_with_index do |work, idx|
        puts "  #{idx + 1}. #{work[:name]} (#{work[:file_path]})"
      end
      
      puts "✅ #{strategy.capitalize} strategy test completed"
      
    rescue => e
      puts "❌ Error testing #{strategy} strategy: #{e.message}"
      puts e.backtrace.first(3).join("\n")
    end
  end
  
  puts "\n" + "="*80
  puts "WORK-BASED DELTA ANALYSIS READY! 🎉"
  puts "="*80
  puts "To run full analysis:"
  puts "  bin/rake delta_analysis:process_works[canonicity,tmp/my_analysis,0.1,composite,20]"
  puts
  puts "To see available works:"
  puts "  bin/rake delta_analysis:show_available_works[canonicity,10]"
  puts
  puts "Quick canonical works analysis:"
  puts "  bin/rake delta_analysis:process_canonical_works[10,0.5]"
  puts "="*80
  
rescue => e
  puts "\n❌ Unexpected error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

main if __FILE__ == $0