#!/usr/bin/env ruby

# Debug script to understand the Work → Text file relationships
require_relative '../config/environment'

puts "🔍 DEBUGGING WORK-FILE RELATIONSHIPS"
puts "=" * 60

# Initialize STI classes properly (required for Shadow table STI)
Shadow.none

# Get top 3 canonical works
works = Work.joins(:attrs).where.not(work_attrs: {obsolete: true})
            .order(measure: :desc, linkcount: :desc)
            .limit(3)

works.each_with_index do |work, idx|
  puts "\n#{idx + 1}. #{work.english || work.what_label || "Work #{work.id}"}"
  puts "   Entity: Q#{work.entity_id} | Measure: #{work.measure&.round(3)} | Links: #{work.linkcount}"
  
  # Show creators
  creators = work.creators
  puts "   Creators: #{creators.map(&:english).join(', ')}" if creators.any?
  
  # For each creator, try to find Author records
  creators.each do |philosopher|
    puts "   Looking for Author records matching: '#{philosopher.english}'"
    
    # Find matching authors
    matching_authors = Author.where(english_name: philosopher.english)
    
    if matching_authors.any?
      matching_authors.each do |author|
        puts "     → Found Author: #{author.english_name} (ID: #{author.id})"
        
        # Check writings
        writings = author.writings
        puts "       - Writings: #{writings.count}"
        
        writings.each do |writing|
          text = writing.text
          puts "         * Text: #{text.name} (ID: #{text.id})"
          
          if text.fyle
            fyle = text.fyle
            absolute_path = fyle.absolute_local_file_path
            status = absolute_path && File.exist?(absolute_path) ? 'EXISTS' : 'MISSING'
            puts "           → Fyle: #{fyle.local_file} → #{absolute_path} (#{status})"
          else
            puts "           → No Fyle attached"
          end
        end
      end
    else
      puts "     → No Author records found for '#{philosopher.english}'"
    end
  end
end

puts "\n" + "=" * 60
puts "📊 SUMMARY STATISTICS"
puts "Total Works: #{Work.count}"
puts "Non-obsolete Works: #{Work.joins(:attrs).where.not(work_attrs: {obsolete: true}).count}"
puts "Total Philosophers: #{Philosopher.count}"
puts "Total Authors: #{Author.count}"
puts "Total Texts: #{Text.count}"
puts "Total Fyles: #{Fyle.count}"
puts "Fyles with local_file: #{Fyle.where.not(local_file: nil).count}"
