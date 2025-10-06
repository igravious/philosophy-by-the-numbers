namespace :delta_phases do
  desc "Count total works with accessible text files"
  task :count_works => :environment do
    puts "🔧 Ruby #{RUBY_VERSION} + Rails #{Rails::VERSION::STRING} Monitor compatibility fix loaded"
    puts
    puts "================================================================================
TEXT-BACKED WORKS COUNT
================================================================================
"
    
    # Ensure models are loaded
    if defined?(Rails)
      require Rails.root.join('app', 'models', 'shadow')
      Shadow.none  # Initialize STI classes
    end
    
    total_works = Work.count
    puts "Total works in database: #{total_works}"
    
    # Use the existing WorkBasedDeltaProcessor logic to count works with files
    require_relative '../delta_analysis/work_based_delta_processor'
    
    # Count all works with files (no canonicity filter)
    all_works_processor = WorkBasedDeltaProcessor.new(
      work_selection_strategy: :canonicity,
      max_works: 10000,
      min_canonicity: 0.0,
      output_dir: '/tmp/count_temp'
    )
    works_with_files = all_works_processor.works_with_files.count
    puts "Works with text files: #{works_with_files}"
    
    # Count works with canonicity >= 3.0 and files
    canonical_processor = WorkBasedDeltaProcessor.new(
      work_selection_strategy: :canonicity,
      max_works: 10000,
      min_canonicity: 3.0,
      output_dir: '/tmp/count_temp'
    )
    canonical_works_with_files = canonical_processor.works_with_files.count
    puts "Works with canonicity >= 3.0 and files: #{canonical_works_with_files}"
    
    # Top canonicity works (simpler query)
    top_works = Work.where('measure IS NOT NULL')
                   .order('measure DESC')
                   .limit(10)
                   
    puts "\nTop 10 works by canonicity (with text files):"
    top_works.each_with_index do |work, i|
      title = work.english || work.what_label || "Work #{work.id}"
      puts "  #{i+1}. #{title} (#{work.measure.round(3)})"
    end
    
    puts "
================================================================================
"
  end
  
  desc "Phase 1: Generate progressive Saffron corpus runs"
  task :saffron_runs, [:max_works, :min_canonicity, :base_dir] => :environment do |t, args|
    max_works = (args[:max_works] || 10).to_i
    min_canonicity = (args[:min_canonicity] || 3.0).to_f
    base_dir = args[:base_dir] || "delta_of_deltas/delta_phases_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
    
    puts "🔧 Ruby #{RUBY_VERSION} + Rails #{Rails::VERSION::STRING} Monitor compatibility fix loaded"
    puts
    puts "================================================================================
PHASE 1: PROGRESSIVE SAFFRON CORPUS GENERATION
================================================================================
Base directory: #{base_dir}
Max works: #{max_works}
Min canonicity: #{min_canonicity}
================================================================================
"
    
    # Use work-based delta processor for work selection
    require_relative '../delta_analysis/work_based_delta_processor'
    processor = WorkBasedDeltaProcessor.new(
      work_selection_strategy: :canonicity,
      max_works: max_works,
      min_canonicity: min_canonicity,
      threshold: 0.05,
      diff_strategy: :composite,
      output_dir: base_dir
    )
    
    # Get selected works with their file paths (already processed by WorkBasedDeltaProcessor)
    works_with_files_data = processor.works_with_files
    
    puts "Selected #{works_with_files_data.count} works for progressive corpus generation"
    puts "Processing order: MOST significant → LEAST significant"
    puts
    
    # Create base directory
    FileUtils.mkdir_p(base_dir)
    
    # Generate progressive corpora: corpus_0001 (1 work), corpus_0002 (2 works), etc.
    works_with_files_data.each_with_index do |work_data, index|
      corpus_id = sprintf("%04d", index + 1)
      corpus_name = "corpus_#{corpus_id}"
      corpus_file = File.join(base_dir, "#{corpus_name}.json")
      results_dir = File.join(base_dir, "saffron_results", corpus_id)
      
      # Use works from index 0 to current index (progressive accumulation)
      current_work_data = works_with_files_data[0..index]
      
      puts "Generating #{corpus_name} with #{current_work_data.count} works:"
      current_work_data.each_with_index do |wd, i|
        work = wd[:work]
        title = work.english || work.what_label || "Work #{work.id}"
        puts "  #{i+1}. #{title} (##{work.id}) - significance: #{work.measure.round(3)}"
      end
      
      # Generate corpus JSON (Saffron only expects "documents" field)
      corpus_data = {
        documents: []
      }
      
      current_work_data.each_with_index do |work_data, doc_index|
        work = work_data[:work]
        file_path = work_data[:file_path]
        
        if File.exist?(file_path)
          content = File.read(file_path, encoding: 'UTF-8')
          
          work_title = work.english || work.what_label || "Work #{work.id}"
          author_names = work.creators.map(&:english).compact
          author_name = author_names.any? ? author_names.join(', ') : "Unknown"
          
          corpus_data[:documents] << {
            id: "work_#{work.id}_doc_#{doc_index + 1}",
            name: work_title,
            authors: [author_name],
            contents: content,
            metadata: {
              philosopher: author_name,
              work_id: work.id,
              significance: work.measure,
              file_path: file_path
            }
          }
        end
      end      # Write corpus JSON
      File.write(corpus_file, JSON.pretty_generate(corpus_data))
      puts "✓ Generated #{corpus_file} (#{corpus_data[:documents].count} documents)"
      
      # Create Saffron config for this corpus (based on working saffron-os-config.json)
      config_file = File.join(base_dir, "saffron_config_#{corpus_id}.json")
      saffron_config = {
        "termExtraction" => {
          "threshold" => 0.0,
          "maxTopics" => 100,
          "ngramMin" => 1,
          "ngramMax" => 4,
          "minTermFreq" => 2,
          "maxDocs" => 2147483647,
          "method" => "voting",
          "features" => ["comboBasic", "weirdness", "totalTfIdf", "cValue", "residualIdf"],
          "corpus" => "${saffron.models}/wiki-terms.json.gz",
          "baseFeature" => "comboBasic",
          "posModel" => "${saffron.models}/en-pos-maxent.bin",
          "tokenizerModel" => nil,
          "lemmatizerModel" => "${saffron.models}/en-lemmatizer.dict.txt",
          "stopWords" => nil,
          "preceedingTokens" => ["NN", "JJ", "NNP", "NNS"],
          "middleTokens" => ["IN"],
          "headTokens" => ["NN", "CD", "NNS"],
          "headTokenFinal" => true,
          "blacklist" => [],
          "blacklistFile" => nil,
          "oneTopicPerDoc" => false
        },
        "authorTerm" => {
          "topN" => 1000,
          "minDocs" => 1
        },
        "authorSim" => {
          "threshold" => 0.1,
          "topN" => 50
        },
        "termSim" => {
          "threshold" => 0.1,
          "topN" => 50
        },
        "taxonomy" => {
          "returnRDF" => false,
          "negSampling" => 5.0,
          "features" => nil,
          "modelFile" => "${saffron.models}/default.json",
          "search" => {
            "algorithm" => "greedy",
            "beamSize" => 20,
            "score" => "simple",
            "baseScore" => "simple",
            "aveChildren" => 3.0,
            "alpha" => 0.01
          }
        }
      }
      File.write(config_file, JSON.pretty_generate(saffron_config))
      
      puts "🚀 To run Saffron for #{corpus_name}:"
      puts "   cd /home/groobiest/saffron-os && ./saffron.sh #{corpus_file} #{results_dir} #{config_file} -k TAXO"
      puts
    end
    
    # Generate handy shell script with all Saffron commands
    saffron_script = File.join(base_dir, "run_saffron.sh")
    script_content = "#!/bin/bash\n"
    script_content += "# Auto-generated Saffron commands for delta analysis\n"
    script_content += "# Generated: #{Time.now.iso8601}\n"
    script_content += "# Base directory: #{base_dir}\n\n"
    script_content += "echo \"Running Saffron on #{works_with_files_data.count} progressive corpora...\"\n"
    script_content += "cd /home/groobiest/saffron-os\n\n"
    
    works_with_files_data.each_with_index do |work_data, index|
      corpus_id = sprintf("%04d", index + 1)
      corpus_name = "corpus_#{corpus_id}"
      corpus_file = File.expand_path(File.join(base_dir, "#{corpus_name}.json"))
      results_dir = File.expand_path(File.join(base_dir, "saffron_results", corpus_id))
      config_file = File.expand_path(File.join(base_dir, "saffron_config_#{corpus_id}.json"))
      
      script_content += "echo \"Processing #{corpus_name}...\"\n"
      script_content += "./saffron.sh #{corpus_file} #{results_dir} #{config_file} -k TAXO\n"
      script_content += "if [ $? -eq 0 ]; then\n"
      script_content += "  echo \"✓ #{corpus_name} completed successfully\"\n"
      script_content += "else\n"
      script_content += "  echo \"❌ #{corpus_name} failed\"\n"
      script_content += "  exit 1\n"
      script_content += "fi\n\n"
    end
    
    script_content += "echo \"🎉 All Saffron runs completed successfully!\"\n"
    script_content += "echo \"Next: cd #{Dir.pwd} && bin/rake delta_phases:calculate_deltas[#{base_dir}]\"\n"
    
    File.write(saffron_script, script_content)
    File.chmod(0755, saffron_script)  # Make executable
    
    puts "================================================================================
PHASE 1 COMPLETE: #{works_with_files_data.count} progressive corpora generated
================================================================================
📝 Saffron commands saved to: #{saffron_script}

Next steps:
  1. Run Saffron: #{saffron_script}
     (This will process all corpora sequentially - can take a while!)
  2. Calculate deltas: bin/rake delta_phases:calculate_deltas[#{base_dir}]
  3. Delta of deltas: bin/rake delta_phases:delta_of_deltas[#{base_dir}]

You can also run individual Saffron commands in parallel if preferred.
"
  end
  
  desc "Phase 2: Calculate deltas between adjacent Saffron results"
  task :calculate_deltas, [:base_dir, :diff_strategy] => :environment do |t, args|
    base_dir = args[:base_dir] || Dir.glob("delta_of_deltas/delta_phases_*").sort.last
    diff_strategy = (args[:diff_strategy] || :composite).to_sym
    
    unless base_dir && Dir.exist?(base_dir)
      puts "❌ Base directory not found: #{base_dir}"
      puts "Run Phase 1 first: rake delta_phases:saffron_runs"
      exit 1
    end
    
    puts "================================================================================
PHASE 2: DELTA CALCULATION BETWEEN ADJACENT RESULTS
================================================================================
Base directory: #{base_dir}
Diff strategy: #{diff_strategy}
================================================================================
"
    
    results_dir = File.join(base_dir, "saffron_results")
    deltas_dir = File.join(base_dir, "deltas")
    FileUtils.mkdir_p(deltas_dir)
    
    # Find all completed Saffron result directories
    completed_results = Dir.glob(File.join(results_dir, "*")).select do |dir|
      Dir.exist?(dir) && File.exist?(File.join(dir, "terms.json"))
    end.sort
    
    if completed_results.count < 2
      puts "❌ Need at least 2 completed Saffron results, found #{completed_results.count}"
      puts "Complete Saffron runs first"
      exit 1
    end
    
    puts "Found #{completed_results.count} completed Saffron results"
    
    # Parse all Saffron results
    parsed_results = {}
    completed_results.each do |result_dir|
      corpus_id = File.basename(result_dir)
      puts "Parsing Saffron results for corpus #{corpus_id}..."
      
      # Parse terms.json
      terms_file = File.join(result_dir, 'terms.json')
      terms_hash = {}
      if File.exist?(terms_file)
        raw_terms = JSON.parse(File.read(terms_file))
        raw_terms.each do |term_data|
          term_string = term_data['term_string']
          score = term_data['score'] || 0.0
          terms_hash[term_string] = score
        end
      end
      
      # Parse doc-terms.json  
      doc_terms_file = File.join(result_dir, 'doc-terms.json')
      doc_terms = {}
      if File.exist?(doc_terms_file)
        raw_doc_terms = JSON.parse(File.read(doc_terms_file))
        raw_doc_terms.each do |doc_term_data|
          doc_id = doc_term_data['document_id']
          term_string = doc_term_data['term_string']
          tfidf = doc_term_data['tfidf'] || 0.0
          
          doc_terms[doc_id] ||= {}
          doc_terms[doc_id][term_string] = tfidf
        end
      end
      
      parsed_results[corpus_id] = {
        corpus_id: corpus_id,
        terms: terms_hash,
        doc_terms: doc_terms,
        term_count: terms_hash.count,
        document_count: doc_terms.count
      }
      
      puts "  ✓ #{terms_hash.count} terms, #{doc_terms.count} documents"
    end
    
    # Calculate deltas between adjacent results
    require_relative '../delta_analysis/custom_diff_strategies'
    
    strategy_class = case diff_strategy
    when :term_weight
      CustomDiffStrategies::TermWeightStrategy
    when :jaccard
      CustomDiffStrategies::JaccardSimilarityStrategy  
    when :semantic
      CustomDiffStrategies::SemanticSimilarityStrategy
    when :composite
      CustomDiffStrategies::CompositeStrategy
    else
      CustomDiffStrategies::CompositeStrategy
    end
    
    delta_results = []
    corpus_ids = parsed_results.keys.sort
    
    (1...corpus_ids.count).each do |i|
      prev_id = corpus_ids[i-1]
      curr_id = corpus_ids[i]
      
      prev_result = parsed_results[prev_id]
      curr_result = parsed_results[curr_id]
      
      puts "Calculating delta: #{prev_id} → #{curr_id}"
      
      # Calculate delta using result objects with :terms keys
      begin
        delta_value = strategy_class.calculate_delta(prev_result, curr_result)
        
        # Extract magnitude from strategy result
        magnitude = delta_value.is_a?(Hash) ? delta_value[:magnitude] : delta_value
        
        delta_data = {
          comparison: "#{prev_id} → #{curr_id}",
          timestamp: Time.now.iso8601,
          strategy: diff_strategy.to_s,
          prev_corpus: {
            id: prev_id,
            term_count: prev_result[:term_count],
            document_count: prev_result[:document_count]
          },
          curr_corpus: {
            id: curr_id,
            term_count: curr_result[:term_count], 
            document_count: curr_result[:document_count]
          },
          delta: magnitude,
          strategy_details: delta_value
        }
        
        # Save individual delta result
        delta_file = File.join(deltas_dir, "D#{sprintf('%04d', i)}.json")
        File.write(delta_file, JSON.pretty_generate(delta_data))
        
        delta_results << delta_data
        puts "  ✓ Delta: #{magnitude.round(6)} → #{delta_file}"
        
      rescue => e
        puts "  ❌ Error calculating delta: #{e.message}"
        puts "     #{e.backtrace.first}"
      end
    end
    
    # Save summary of all deltas
    summary_file = File.join(deltas_dir, "delta_summary.json")
    summary_data = {
      base_dir: base_dir,
      strategy: diff_strategy.to_s,
      timestamp: Time.now.iso8601,
      total_comparisons: delta_results.count,
      deltas: delta_results
    }
    File.write(summary_file, JSON.pretty_generate(summary_data))
    
    puts "
================================================================================
PHASE 2 COMPLETE: #{delta_results.count} deltas calculated
================================================================================
Delta progression:"
    delta_results.each do |d|
      puts "  #{d[:comparison]}: #{d[:delta].round(6)}"
    end
    puts "
Summary saved to: #{summary_file}
Next: rake delta_phases:delta_of_deltas[#{base_dir}]
"
  end
  
  desc "Phase 3: Calculate delta of deltas for convergence detection"
  task :delta_of_deltas, [:base_dir, :convergence_threshold] => :environment do |t, args|
    base_dir = args[:base_dir] || Dir.glob("delta_of_deltas/delta_phases_*").sort.last
    threshold = (args[:convergence_threshold] || 0.01).to_f
    
    deltas_dir = File.join(base_dir, "deltas")
    summary_file = File.join(deltas_dir, "delta_summary.json")
    
    unless File.exist?(summary_file)
      puts "❌ Delta summary not found: #{summary_file}"
      puts "Run Phase 2 first: rake delta_phases:calculate_deltas"
      exit 1
    end
    
    puts "================================================================================
PHASE 3: DELTA OF DELTAS - CONVERGENCE DETECTION
================================================================================
Base directory: #{base_dir}
Convergence threshold: #{threshold}
================================================================================
"
    
    # Load delta results
    summary_data = JSON.parse(File.read(summary_file))
    deltas = summary_data['deltas'].map { |d| d['delta'] }
    
    if deltas.count < 2
      puts "❌ Need at least 2 deltas to calculate delta of deltas"
      exit 1
    end
    
    puts "Loaded #{deltas.count} delta values:"
    deltas.each_with_index do |delta, i|
      puts "  D#{sprintf('%04d', i+1)}: #{delta.round(6)}"
    end
    puts
    
    # Calculate delta of deltas (rate of change between adjacent deltas)
    delta_of_deltas = []
    (1...deltas.count).each do |i|
      prev_delta = deltas[i-1]
      curr_delta = deltas[i]
      
      # Calculate absolute difference between adjacent deltas
      delta_of_delta = (curr_delta - prev_delta).abs
      delta_of_deltas << delta_of_delta
      
      puts "ΔΔ#{sprintf('%04d', i)}: |#{curr_delta.round(6)} - #{prev_delta.round(6)}| = #{delta_of_delta.round(6)}"
    end
    
    puts
    puts "Delta of Deltas progression:"
    delta_of_deltas.each_with_index do |dd, i|
      status = dd < threshold ? "✓ CONVERGED" : "△ changing"
      puts "  ΔΔ#{sprintf('%04d', i+1)}: #{dd.round(6)} #{status}"
    end
    
    # Detect convergence
    converged_at = nil
    delta_of_deltas.each_with_index do |dd, i|
      if dd < threshold
        converged_at = i + 1
        break
      end
    end
    
    puts
    if converged_at
      corpus_at_convergence = converged_at + 1  # +1 because delta_of_deltas is 0-indexed but corpus is 1-indexed
      puts "🎯 CONVERGENCE DETECTED at ΔΔ#{sprintf('%04d', converged_at)} (corpus #{sprintf('%04d', corpus_at_convergence)})"
      puts "   Delta of delta: #{delta_of_deltas[converged_at-1].round(6)} < threshold #{threshold}"
      puts "   This suggests term extraction stabilized after processing #{corpus_at_convergence} works"
    else
      puts "⚠️  NO CONVERGENCE detected - delta of deltas still above threshold #{threshold}"
      puts "   Consider processing more works or adjusting convergence threshold"
    end
    
    # Save delta of deltas results
    convergence_file = File.join(base_dir, "convergence_analysis.json")
    convergence_data = {
      base_dir: base_dir,
      timestamp: Time.now.iso8601,
      threshold: threshold,
      deltas: deltas,
      delta_of_deltas: delta_of_deltas,
      converged: !converged_at.nil?,
      converged_at_index: converged_at,
      converged_at_corpus: converged_at ? converged_at + 1 : nil,
      analysis: {
        total_works_processed: deltas.count + 1,
        total_delta_comparisons: deltas.count,
        total_delta_of_delta_comparisons: delta_of_deltas.count,
        min_delta: deltas.min,
        max_delta: deltas.max,
        final_delta: deltas.last,
        min_delta_of_delta: delta_of_deltas.min,
        max_delta_of_delta: delta_of_deltas.max,
        final_delta_of_delta: delta_of_deltas.last
      }
    }
    File.write(convergence_file, JSON.pretty_generate(convergence_data))
    
    puts "
================================================================================
PHASE 3 COMPLETE: Convergence analysis saved to #{convergence_file}
================================================================================
"
  end
end