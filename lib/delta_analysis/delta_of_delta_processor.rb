# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'open3'
require_relative 'custom_diff_strategies'

# DeltaOfDeltaProcessor implements the "difference of differences" algorithm
# for analyzing philosophical works using Saffron term extraction.
#
# The algorithm processes works in order of significance:
# 1. Run Saffron on cumulative sets of works (A, A+B, A+B+C, ...)
# 2. Calculate deltas between consecutive results (dAB, dBC, dCD, ...)
# 3. Calculate delta of deltas (ddABdBC, ddBCdCD, ...)
# 4. Continue until delta of delta drops below threshold
class DeltaOfDeltaProcessor
  SAFFRON_PATH = File.expand_path('~/saffron-os')
  SAFFRON_SCRIPT = File.join(SAFFRON_PATH, 'saffron.sh')
  
  attr_reader :works, :output_dir, :threshold, :config_file, :diff_strategy
  attr_accessor :current_iteration, :results_history, :deltas_history, :delta_of_deltas_history

  def initialize(works:, output_dir:, threshold: 0.1, config_file: nil, diff_strategy: :composite)
    @works = works # Array of work file paths in SIGNIFICANCE ORDER (most significant first)
    @output_dir = File.expand_path(output_dir)
    @threshold = threshold
    @diff_strategy = diff_strategy
    @current_iteration = 0
    @results_history = [] # Store Saffron results for each cumulative set
    @deltas_history = [] # Store deltas between consecutive results
    @delta_of_deltas_history = [] # Store delta of deltas
    
    setup_directories
    @config_file = config_file || default_config_file
  end

  # Main processing method - runs the complete delta of delta algorithm
  # CRITICAL: Works must be ordered from MOST significant to LEAST significant
  def process
    puts "Starting Delta of Delta processing with #{works.length} works"
    puts "Threshold: #{threshold}"
    puts "Output directory: #{output_dir}"
    puts "Processing order: MOST significant → LEAST significant"
    
    # Process first work
    result_a = process_cumulative_works([works[0]], 'A')
    @results_history << result_a
    
    return if works.length < 2
    
    # Process remaining works iteratively
    (1...works.length).each do |i|
      iteration_letter = (65 + i).chr # B, C, D, ...
      
      # Get cumulative works up to current iteration
      cumulative_works = works[0..i]
      
      # Run Saffron on cumulative set
      result_current = process_cumulative_works(cumulative_works, iteration_letter)
      @results_history << result_current
      
      # Calculate delta between previous and current results
      delta = calculate_delta(@results_history[-2], result_current)
      @deltas_history << delta
      
      # If we have at least 2 deltas, calculate delta of delta
      if @deltas_history.length >= 2
        delta_of_delta = calculate_delta_of_delta(@deltas_history[-2], @deltas_history[-1])
        @delta_of_deltas_history << delta_of_delta
        
        puts "Iteration #{iteration_letter}: Delta of Delta = #{delta_of_delta[:magnitude]}"
        
        # Check if we've reached convergence
        if delta_of_delta[:magnitude] < threshold
          puts "Convergence reached! Delta of Delta (#{delta_of_delta[:magnitude]}) below threshold (#{threshold})"
          break
        end
      end
      
      @current_iteration = i
    end
    
    generate_final_report
  end

  private

  def setup_directories
    FileUtils.mkdir_p(@output_dir)
    FileUtils.mkdir_p(File.join(@output_dir, 'saffron_results'))
    FileUtils.mkdir_p(File.join(@output_dir, 'deltas'))
    FileUtils.mkdir_p(File.join(@output_dir, 'reports'))
  end

  def process_cumulative_works(work_files, iteration_id)
    puts "Processing iteration #{iteration_id} with #{work_files.length} works"
    
    # Create JSON corpus file for this iteration
    corpus_json_file = File.join(@output_dir, "corpus_#{iteration_id}.json")
    generate_corpus_json(work_files, corpus_json_file, iteration_id)
    
    # Run Saffron on the JSON corpus
    saffron_output_dir = File.join(@output_dir, 'saffron_results', iteration_id)
    run_saffron(corpus_json_file, saffron_output_dir)
    
    # Parse and return results
    parse_saffron_results(saffron_output_dir, iteration_id)
  end

  def run_saffron(corpus_file, output_dir)
    # Convert to absolute paths since we'll change directory
    abs_corpus_file = File.expand_path(corpus_file)
    abs_output_dir = File.expand_path(output_dir)
    abs_config_file = File.expand_path(@config_file)
    
    # Saffron script should be run from the Saffron directory
    # Use -k TAXO flag to avoid KG building issues
    script_name = './saffron.sh'
    cmd = [script_name, abs_corpus_file, abs_output_dir, abs_config_file, '-k', 'TAXO']
    
    puts "Running Saffron from #{SAFFRON_PATH}: #{cmd.join(' ')}"
    
    # Change to Saffron directory and run the command
    stdout, stderr, status = Open3.capture3(*cmd, chdir: SAFFRON_PATH)
    
    unless status.success?
      raise "Saffron execution failed: #{stderr}"
    end
    
    puts "Saffron completed successfully"
    stdout
  end

  def parse_saffron_results(results_dir, iteration_id)
    results = {
      iteration_id: iteration_id,
      timestamp: Time.now,
      terms: {},
      doc_terms: {},
      author_terms: {},
      term_similarity: {},
      results_dir: results_dir
    }
    
    # Parse terms.json if it exists
    terms_file = File.join(results_dir, 'terms.json')
    if File.exist?(terms_file)
      raw_terms = JSON.parse(File.read(terms_file))
      puts "Parsed #{raw_terms.length} terms from Saffron output"
      
      # Convert Saffron's array format to hash format expected by delta calculations
      # Saffron format: [{"term_string": "...", "score": ..., "occurrences": ...}, ...]
      results[:terms] = {}
      raw_terms.each do |term_data|
        if term_data.is_a?(Hash) && term_data['term_string']
          term_key = term_data['term_string']
          results[:terms][term_key] = {
            'term' => term_key,
            'score' => term_data['score'] || 0.0,
            'occurrences' => term_data['occurrences'] || 0,
            'matches' => term_data['matches'] || 0
          }
        end
      end
      puts "Converted to #{results[:terms].length} term hash entries"
    end
    
    # Parse doc-terms.json if it exists
    doc_terms_file = File.join(results_dir, 'doc-terms.json')
    if File.exist?(doc_terms_file)
      raw_doc_terms = JSON.parse(File.read(doc_terms_file))
      puts "Parsed #{raw_doc_terms.length} doc-term associations from Saffron output"
      
      # Convert Saffron's array format to structured format
      # Saffron format: [{"document_id": "...", "term_string": "...", "occurrences": ..., "tfidf": ...}, ...]
      results[:doc_terms] = {}
      raw_doc_terms.each do |doc_term_data|
        if doc_term_data.is_a?(Hash) && doc_term_data['document_id'] && doc_term_data['term_string']
          doc_id = doc_term_data['document_id']
          term = doc_term_data['term_string']
          
          results[:doc_terms][doc_id] ||= {}
          results[:doc_terms][doc_id][term] = {
            'occurrences' => doc_term_data['occurrences'] || 0,
            'tfidf' => doc_term_data['tfidf'] || 0.0
          }
        end
      end
      puts "Organized into #{results[:doc_terms].length} documents with terms"
    end
    
    # Parse author-terms.json if it exists
    author_terms_file = File.join(results_dir, 'author-terms.json')
    if File.exist?(author_terms_file)
      raw_author_terms = JSON.parse(File.read(author_terms_file))
      puts "Parsed #{raw_author_terms.length} author-term associations from Saffron output"
      
      # Convert Saffron's array format (if populated) to structured format
      results[:author_terms] = {}
      if raw_author_terms.is_a?(Array) && raw_author_terms.any?
        raw_author_terms.each do |author_term_data|
          if author_term_data.is_a?(Hash) && author_term_data['author'] && author_term_data['term']
            author = author_term_data['author']
            term = author_term_data['term']
            
            results[:author_terms][author] ||= {}
            results[:author_terms][author][term] = author_term_data['score'] || 0.0
          end
        end
      end
    end
    
    # Parse term-sim.json if it exists
    term_sim_file = File.join(results_dir, 'term-sim.json')
    if File.exist?(term_sim_file)
      results[:term_similarity] = JSON.parse(File.read(term_sim_file))
    end
    
    # Save parsed results
    results_file = File.join(@output_dir, 'reports', "parsed_results_#{iteration_id}.json")
    File.write(results_file, JSON.pretty_generate(results))
    
    results
  end

  def calculate_delta(result_a, result_b)
    # Use custom diff strategy
    strategy_class = case @diff_strategy
    when :term_weight
      CustomDiffStrategies::TermWeightStrategy
    when :semantic_similarity
      CustomDiffStrategies::SemanticSimilarityStrategy
    when :document_distribution
      CustomDiffStrategies::DocumentDistributionStrategy
    when :composite
      CustomDiffStrategies::CompositeStrategy
    else
      CustomDiffStrategies::CompositeStrategy
    end
    
    strategy_result = strategy_class.calculate_delta(result_a, result_b)
    
    delta = {
      comparison: "#{result_a[:iteration_id]} -> #{result_b[:iteration_id]}",
      timestamp: Time.now,
      strategy: @diff_strategy.to_s,
      magnitude: strategy_result[:magnitude],
      strategy_details: strategy_result[:details],
      # Keep legacy format for backward compatibility
      terms_delta: calculate_terms_delta(result_a[:terms], result_b[:terms]),
      doc_terms_delta: calculate_doc_terms_delta(result_a[:doc_terms], result_b[:doc_terms])
    }
    
    # Save delta
    delta_file = File.join(@output_dir, 'deltas', "delta_#{delta[:comparison].gsub(' -> ', '_to_')}.json")
    File.write(delta_file, JSON.pretty_generate(delta))
    
    delta
  end

  def calculate_terms_delta(terms_a, terms_b)
    return {} if terms_a.nil? || terms_b.nil?
    
    # Convert to sets for comparison
    terms_a_set = Set.new(terms_a.keys)
    terms_b_set = Set.new(terms_b.keys)
    
    {
      added_terms: (terms_b_set - terms_a_set).to_a,
      removed_terms: (terms_a_set - terms_b_set).to_a,
      common_terms: (terms_a_set & terms_b_set).to_a,
      weight_changes: calculate_weight_changes(terms_a, terms_b, terms_a_set & terms_b_set)
    }
  end

  def calculate_doc_terms_delta(doc_terms_a, doc_terms_b)
    return {} if doc_terms_a.nil? || doc_terms_b.nil?
    
    # Implement document-term relationship changes
    {
      documents_added: doc_terms_b.keys - doc_terms_a.keys,
      documents_removed: doc_terms_a.keys - doc_terms_b.keys,
      term_distribution_changes: calculate_term_distribution_changes(doc_terms_a, doc_terms_b)
    }
  end

  def calculate_weight_changes(terms_a, terms_b, common_terms)
    changes = {}
    common_terms.each do |term|
      weight_a = terms_a[term].is_a?(Hash) ? terms_a[term]['score'] || terms_a[term]['weight'] || 0 : 0
      weight_b = terms_b[term].is_a?(Hash) ? terms_b[term]['score'] || terms_b[term]['weight'] || 0 : 0
      
      if weight_a != weight_b
        changes[term] = {
          old_weight: weight_a,
          new_weight: weight_b,
          change: weight_b - weight_a
        }
      end
    end
    changes
  end

  def calculate_term_distribution_changes(doc_terms_a, doc_terms_b)
    # This is a placeholder - implement according to your specific needs
    # Could analyze how term frequencies change across documents
    {}
  end

  def calculate_delta_magnitude(delta)
    # Custom magnitude calculation - implement your specific strategy
    terms_delta = delta[:terms_delta]
    return 0.0 if terms_delta.empty?
    
    added_count = terms_delta[:added_terms]&.length || 0
    removed_count = terms_delta[:removed_terms]&.length || 0
    weight_changes_count = terms_delta[:weight_changes]&.length || 0
    
    # Simple magnitude based on proportion of changes
    total_terms = (terms_delta[:common_terms]&.length || 0) + added_count
    return 0.0 if total_terms == 0
    
    (added_count + removed_count + weight_changes_count).to_f / total_terms
  end

  def calculate_delta_of_delta(delta_a, delta_b)
    delta_of_delta = {
      comparison: "d(#{delta_a[:comparison]}) vs d(#{delta_b[:comparison]})",
      timestamp: Time.now,
      magnitude_change: delta_b[:magnitude] - delta_a[:magnitude],
      magnitude: 0.0
    }
    
    # Calculate delta of delta magnitude (rate of change of the rate of change)
    delta_of_delta[:magnitude] = (delta_of_delta[:magnitude_change]).abs
    
    # Save delta of delta
    dd_file = File.join(@output_dir, 'deltas', "delta_of_delta_#{@delta_of_deltas_history.length + 1}.json")
    File.write(dd_file, JSON.pretty_generate(delta_of_delta))
    
    delta_of_delta
  end

  def generate_final_report
    report = {
      summary: {
        total_works_processed: @current_iteration + 1,
        total_iterations: @results_history.length,
        final_threshold: @threshold,
        convergence_reached: (@delta_of_deltas_history.last&.dig(:magnitude) || Float::INFINITY) < @threshold,
        processing_time: Time.now
      },
      works_processed: @works[0..@current_iteration],
      results_summary: @results_history.map { |r| 
        {
          iteration: r[:iteration_id],
          terms_count: r[:terms]&.length || 0,
          timestamp: r[:timestamp]
        }
      },
      deltas_summary: @deltas_history.map.with_index { |d, i| 
        {
          comparison: d[:comparison],
          magnitude: d[:magnitude],
          iteration: i + 1
        }
      },
      delta_of_deltas_summary: @delta_of_deltas_history.map.with_index { |dd, i|
        {
          comparison: dd[:comparison],
          magnitude: dd[:magnitude],
          magnitude_change: dd[:magnitude_change],
          iteration: i + 1
        }
      }
    }
    
    report_file = File.join(@output_dir, 'reports', 'final_report.json')
    File.write(report_file, JSON.pretty_generate(report))
    
    puts "\n" + "="*80
    puts "DELTA OF DELTA PROCESSING COMPLETE"
    puts "="*80
    puts "Works processed: #{report[:summary][:total_works_processed]}/#{@works.length}"
    puts "Convergence reached: #{report[:summary][:convergence_reached] ? 'YES' : 'NO'}"
    if @delta_of_deltas_history.any?
      puts "Final delta of delta: #{@delta_of_deltas_history.last[:magnitude]}"
    end
    puts "Full report saved to: #{report_file}"
    puts "="*80
    
    report
  end

  def default_config_file
    # Create a custom config optimized for term extraction only
    config_path = File.join(@output_dir, 'saffron_config.json')
    
    # Configuration optimized for term extraction and taxonomy (no KG)
    default_config = {
      "termExtraction" => {
        "threshold" => 0.0,
        "maxTerms" => 100,
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
        "topN" => 100,
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
      },
      "kg" => {
        "kerasModelFile" => "/dev/null",
        "bertModelFile" => "/dev/null",
        "numberOfRelations" => 0,
        "synonymyThreshold" => 0.999,
        "meronomyThreshold" => 0.999,
        "enableSynonymyNormalisation" => false,
        "returnRDF" => false
      }
    }
    
    File.write(config_path, JSON.pretty_generate(default_config))
    
    config_path
  end
  
  # Generate Saffron JSON corpus file from work files
  def generate_corpus_json(work_files, output_file, iteration_id)
    corpus_data = {
      documents: []
    }
    
    work_files.each_with_index do |work_file, idx|
      if File.exist?(work_file)
        document = {
          id: "work_#{idx}_#{iteration_id}",
          name: File.basename(work_file, ".*"),
          file: work_file,
          metadata: {
            iteration: iteration_id,
            position: idx + 1,
            total_works: work_files.length
          }
        }
        
        corpus_data[:documents] << document
      else
        puts "Warning: Work file not found: #{work_file}"
      end
    end
    
    File.write(output_file, JSON.pretty_generate(corpus_data))
    puts "Generated corpus JSON: #{output_file} (#{corpus_data[:documents].length} documents)"
  end
end