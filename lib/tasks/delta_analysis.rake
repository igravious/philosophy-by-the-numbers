# frozen_string_literal: true

namespace :delta_analysis do
  desc "Run Delta of Delta analysis on philosophical works"
  task :process, [:works_pattern, :output_dir, :threshold, :diff_strategy] => :environment do |task, args|
    require_relative '../lib/delta_analysis/delta_of_delta_processor'
    
    # Default arguments
    works_pattern = args[:works_pattern] || '_txt/**/*.txt'
    output_dir = args[:output_dir] || 'tmp/delta_analysis'
    threshold = (args[:threshold] || '0.1').to_f
    diff_strategy = (args[:diff_strategy] || 'composite').to_sym
    
    # Find works matching the pattern
    works = Dir.glob(File.join(Rails.root, works_pattern)).sort
    
    if works.empty?
      puts "No works found matching pattern: #{works_pattern}"
      puts "Available files in _txt/:"
      Dir.glob(File.join(Rails.root, '_txt/**/*')).each { |f| puts "  #{f}" }
      exit 1
    end
    
    puts "Found #{works.length} works matching pattern: #{works_pattern}"
    puts "Sample works:"
    works.first(5).each { |w| puts "  #{w}" }
    puts "  ... and #{works.length - 5} more" if works.length > 5
    
    puts "Using diff strategy: #{diff_strategy}"
    
    # Initialize processor
    processor = DeltaOfDeltaProcessor.new(
      works: works,
      output_dir: output_dir,
      threshold: threshold,
      diff_strategy: diff_strategy
    )
    
    # Run the analysis
    begin
      processor.process
    rescue => e
      puts "Error during delta analysis: #{e.message}"
      puts e.backtrace.first(10).join("\n")
      exit 1
    end
  end
  
  desc "List available works for delta analysis"
  task :list_works, [:pattern] => :environment do |task, args|
    pattern = args[:pattern] || '_txt/**/*.txt'
    works = Dir.glob(File.join(Rails.root, pattern)).sort
    
    puts "Works matching pattern '#{pattern}':"
    puts "=" * 50
    works.each_with_index do |work, idx|
      size = File.size(work)
      puts "#{idx + 1}. #{work} (#{size} bytes)"
    end
    puts "=" * 50
    puts "Total: #{works.length} works"
  end
  
  desc "Test Saffron installation"
  task :test_saffron do
    require_relative '../lib/delta_analysis/delta_of_delta_processor'
    
    puts "Testing Saffron installation..."
    puts "Saffron path: #{DeltaOfDeltaProcessor::SAFFRON_PATH}"
    puts "Saffron script: #{DeltaOfDeltaProcessor::SAFFRON_SCRIPT}"
    
    if File.exist?(DeltaOfDeltaProcessor::SAFFRON_SCRIPT)
      puts "✓ Saffron script found"
      
      # Test with example from Saffron docs
      test_cmd = "cd #{DeltaOfDeltaProcessor::SAFFRON_PATH} && ./saffron.sh --help"
      puts "Running: #{test_cmd}"
      
      result = system(test_cmd)
      if result
        puts "✓ Saffron appears to be working"
      else
        puts "✗ Saffron test failed"
      end
    else
      puts "✗ Saffron script not found at #{DeltaOfDeltaProcessor::SAFFRON_SCRIPT}"
      puts "Make sure Saffron is installed at ~/saffron-os"
    end
  end
  
  desc "Create example works for testing delta analysis"
  task :create_test_works => :environment do
    test_dir = File.join(Rails.root, 'tmp', 'test_works')
    FileUtils.mkdir_p(test_dir)
    
    # Create some sample philosophical texts for testing
    works = [
      {
        filename: 'work_a.txt',
        content: <<~TEXT
          On the Nature of Being
          
          What is being? This fundamental question has occupied philosophers since ancient times.
          Being is the most general concept, applicable to everything that exists.
          To be is to have reality, to possess existence in some form.
          The study of being is called ontology, a branch of metaphysics.
          
          Existence manifests in various forms: material objects, thoughts, numbers, possibilities.
          Each mode of being presents unique characteristics and challenges for understanding.
          The relationship between being and becoming has been central to philosophical inquiry.
        TEXT
      },
      {
        filename: 'work_b.txt',
        content: <<~TEXT
          On the Nature of Being and Knowledge
          
          What is being? This fundamental question has occupied philosophers since ancient times.
          Being is the most general concept, applicable to everything that exists.
          To be is to have reality, to possess existence in some form.
          The study of being is called ontology, a branch of metaphysics.
          
          But how do we know being? Knowledge of being requires both reason and experience.
          Epistemology, the study of knowledge, intersects with ontology in profound ways.
          We cannot separate what we know from how we know it.
          
          Existence manifests in various forms: material objects, thoughts, numbers, possibilities.
          Each mode of being presents unique characteristics and challenges for understanding.
          The relationship between being and becoming has been central to philosophical inquiry.
          
          Truth emerges from the correspondence between mind and reality.
          The knowing subject and the known object are intimately connected.
        TEXT
      },
      {
        filename: 'work_c.txt',
        content: <<~TEXT
          On the Nature of Being, Knowledge, and Ethics
          
          What is being? This fundamental question has occupied philosophers since ancient times.
          Being is the most general concept, applicable to everything that exists.
          To be is to have reality, to possess existence in some form.
          The study of being is called ontology, a branch of metaphysics.
          
          But how do we know being? Knowledge of being requires both reason and experience.
          Epistemology, the study of knowledge, intersects with ontology in profound ways.
          We cannot separate what we know from how we know it.
          
          The ethical dimension emerges when we consider how we ought to live.
          Moral philosophy depends on our understanding of human nature and reality.
          What is good? What actions are right? These questions connect to being itself.
          
          Existence manifests in various forms: material objects, thoughts, numbers, possibilities.
          Each mode of being presents unique characteristics and challenges for understanding.
          The relationship between being and becoming has been central to philosophical inquiry.
          
          Truth emerges from the correspondence between mind and reality.
          The knowing subject and the known object are intimately connected.
          
          Virtue ethics focuses on character rather than actions or consequences.
          The good life involves the cultivation of excellence in thought and deed.
          Happiness (eudaimonia) is the highest human good, achieved through virtue.
        TEXT
      }
    ]
    
    works.each do |work|
      file_path = File.join(test_dir, work[:filename])
      File.write(file_path, work[:content])
      puts "Created test work: #{file_path}"
    end
    
    puts "\nTest works created in: #{test_dir}"
    puts "You can now test the delta analysis with:"
    puts "  bin/rake delta_analysis:process[tmp/test_works/*.txt,tmp/delta_test_output,0.05]"
  end
  
  desc "Run Delta of Delta analysis using works from Shadow table"
  task :process_works, [:strategy, :output_dir, :threshold, :diff_strategy, :max_works, :min_canonicity] => :environment do |task, args|
    require_relative '../delta_analysis/work_based_delta_processor'
    
    # Default arguments
    strategy = (args[:strategy] || 'canonicity').to_sym
    output_dir = args[:output_dir] || 'tmp/delta_works_analysis'
    threshold = (args[:threshold] || '0.1').to_f
    diff_strategy = (args[:diff_strategy] || 'composite').to_sym
    max_works = (args[:max_works] || '50').to_i
    min_canonicity = args[:min_canonicity]&.to_f
    
    puts "Delta Analysis using Shadow table works:"
    puts "  Strategy: #{strategy}"
    puts "  Max works: #{max_works}"
    puts "  Min measure: #{min_canonicity || 'none'}"
    puts "  Threshold: #{threshold}"
    puts "  Diff strategy: #{diff_strategy}"
    puts "  Output: #{output_dir}"
    
    # Initialize processor
    processor = WorkBasedDeltaProcessor.new(
      work_selection_strategy: strategy,
      max_works: max_works,
      min_canonicity: min_canonicity,
      output_dir: output_dir,
      threshold: threshold,
      diff_strategy: diff_strategy
    )
    
    # Run the analysis
    begin
      processor.process
    rescue => e
      puts "Error during work-based delta analysis: #{e.message}"
      puts e.backtrace.first(10).join("\n")
      exit 1
    end
  end
  
  desc "Quick work-based delta analysis with high canonicity works"
  task :process_canonical_works, [:max_works, :min_canonicity] => :environment do |task, args|
    max_works = (args[:max_works] || '20').to_i
    min_canonicity = (args[:min_canonicity] || '0.5').to_f
    
    Rake::Task['delta_analysis:process_works'].invoke(
      'canonicity',
      'tmp/delta_canonical_works',
      '0.05',
      'composite', 
      max_works.to_s,
      min_canonicity.to_s
    )
  end
  
  desc "Show available works for delta analysis with statistics"
  task :show_available_works, [:strategy, :limit] => :environment do |task, args|
    Shadow.none  # Load the Shadow models
    strategy = (args[:strategy] || 'canonicity').to_sym
    limit = (args[:limit] || '20').to_i
    
    puts "Available works for Delta analysis (strategy: #{strategy}):"
    puts "=" * 80
    
    # Get works using the same selection logic
    case strategy
    when :canonicity
      # Get all non-obsolete works ordered by significance
      works = Work.where.not(obsolete: true)
                 .order(measure: :desc, linkcount: :desc)
                 .limit(limit)
    when :linkcount
      # Get all non-obsolete works ordered by linkcount
      works = Work.where.not(obsolete: true)
                 .order(linkcount: :desc)
                 .limit(limit)
    else
      puts "Unknown strategy: #{strategy}"
      exit 1
    end
    
    works.each_with_index do |work, idx|
      measure = work.measure&.round(3) || 'N/A'
      name = work.english || work.what_label || "Work #{work.id}"
      
      # Try to find a text file via the complex relationship chain
      file_path = nil
      file_size = 0
      
      work.creators.each do |philosopher|
        # Find corresponding Fyle records by matching author english name
        fyles = Fyle.joins(text: { writings: :author })
                    .where('fyles.local_file IS NOT NULL')
                    .where('authors.english_name = ?', philosopher.english)
        
        fyles.each do |fyle|
          file_path = fyle.absolute_local_file_path
          if file_path && File.exist?(file_path)
            file_size = File.size(file_path)
            break # Use first available file
          end
        end
        
        break if file_path # Stop looking through philosophers if we found a file
      end
      
      file_info = file_path ? "#{file_path} (#{file_size} bytes)" : "No text file found"
      philosophers = work.creators.map(&:english).compact.join(', ')
      
      puts "#{(idx + 1).to_s.rjust(3)}. #{name}"
      puts "     Entity: Q#{work.entity_id} | Measure: #{measure} | Links: #{work.linkcount}"
      puts "     Philosophers: #{philosophers}" if philosophers.present?
      puts "     File: #{file_info}"
      puts
    end
    
    puts "=" * 80
    puts "Total works: #{Work.where.not(obsolete: true).count}"
    puts "Note: File availability is determined through Work → Philosopher → Author → Text → Fyle relationships"
  end
end