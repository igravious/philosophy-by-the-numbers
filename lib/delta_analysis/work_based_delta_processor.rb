# frozen_string_literal: true

require_relative 'delta_of_delta_processor'

# Ensure Rails models are loaded
if defined?(Rails)
  require Rails.root.join('app', 'models', 'shadow')
  # Initialize STI classes properly (required for Shadow table STI)
  Shadow.none
end

# WorkBasedDeltaProcessor extends the base DeltaOfDeltaProcessor to work with
# philosophical works from the Shadow table instead of raw file paths.
# 
# This integrates the delta of delta algorithm with CorpusBuilder's data model,
# using canonicity measures and significance rankings from the database.
class WorkBasedDeltaProcessor < DeltaOfDeltaProcessor
  
  attr_reader :work_selection_strategy, :min_canonicity, :max_works, :works_with_files
  
  def initialize(work_selection_strategy: :canonicity, min_canonicity: nil, max_works: 50, **args)
    @work_selection_strategy = work_selection_strategy
    @min_canonicity = min_canonicity  
    @max_works = max_works
    
    # Get works from the database and prepare work-file pairs
    works_data = select_works
    @works_with_files = prepare_works_with_files(works_data)
    
    # Extract just file paths for parent class compatibility
    file_paths = @works_with_files.map { |wf| wf[:file_path] }.compact
    
    # Store work metadata for reporting
    @work_metadata = @works_with_files.map.with_index do |work_data, index|
      work = work_data[:work]
      {
        id: work.id,
        entity_id: work.entity_id,
        name: work.english || work.what_label || "Work #{work.id}",
        measure: work.measure,  # Use 'measure' field (the actual canonicity measure)
        linkcount: work.linkcount,
        philosophers: work_philosophers(work),
        file_path: work_data[:file_path],
        significance_rank: index + 1
      }
    end
    
    puts "Selected #{file_paths.length} works using strategy: #{work_selection_strategy}"
    puts "Works with files: #{file_paths.compact.length}"
    
    # Validate significance ordering
    if @work_metadata.length >= 2
      case work_selection_strategy
      when :canonicity
        first_measure = @work_metadata.first[:measure] || 0
        last_measure = @work_metadata.last[:measure] || 0
        puts "✓ Significance ordering: #{first_measure.round(3)} (most) → #{last_measure.round(3)} (least)"
      when :linkcount, :mixed
        first_links = @work_metadata.first[:linkcount] || 0
        last_links = @work_metadata.last[:linkcount] || 0
        puts "✓ Significance ordering: #{first_links} links (most) → #{last_links} links (least)"
      end
    end
    
    # Initialize parent with file paths (ordered from most to least significant)
    super(works: file_paths.compact, **args)
  end
  
  # Override process method to include work metadata in reports
  def process
    puts "\n" + "="*80
    puts "WORK-BASED DELTA OF DELTA ANALYSIS"
    puts "="*80
    puts "Selection strategy: #{@work_selection_strategy}"
    puts "Min canonicity: #{@min_canonicity || 'none'}"
    puts "Max works: #{@max_works}"
    puts "Works selected: #{@work_metadata.length}"
    puts "Works with files: #{@works.length}"
    puts "="*80
    
    result = super
    
    # Enhance the final report with work metadata
    enhanced_report = result.deep_dup
    enhanced_report[:work_metadata] = @work_metadata
    enhanced_report[:selection_strategy] = @work_selection_strategy
    enhanced_report[:selection_criteria] = {
      min_canonicity: @min_canonicity,
      max_works: @max_works
    }
    
    # Save enhanced report
    enhanced_report_file = File.join(@output_dir, 'reports', 'enhanced_final_report.json')
    File.write(enhanced_report_file, JSON.pretty_generate(enhanced_report))
    
    puts "\n📊 WORK SELECTION SUMMARY:"
    puts "Strategy: #{@work_selection_strategy}"
    puts "Total works in corpus: #{Work.count}"
    puts "Works with texts: #{Work.joins(:text).count}"
    puts "Works selected: #{@work_metadata.length}"
    puts "Files processed: #{@works.length}"
    
    if @work_metadata.any?
      puts "\n🏆 TOP WORKS PROCESSED:"
      @work_metadata.first(5).each_with_index do |work, idx|
        measure_info = work[:measure] ? " (measure: #{work[:measure].round(3)})" : ""
        linkcount_info = work[:linkcount] ? " [#{work[:linkcount]} links]" : ""
        philosophers_info = work[:philosophers].any? ? " by #{work[:philosophers].join(', ')}" : ""
        puts "  #{idx + 1}. #{work[:name]}#{measure_info}#{linkcount_info}#{philosophers_info}"
      end
    end
    
    enhanced_report
  end
  
  private
  
  def select_works
    case @work_selection_strategy
    when :canonicity
      select_by_canonicity
    when :linkcount
      select_by_linkcount
    when :mixed
      select_by_mixed_ranking
    when :random
      select_randomly
    when :recent
      select_recent_additions
    else
      raise ArgumentError, "Unknown work selection strategy: #{@work_selection_strategy}"
    end
  end
  
  def select_by_canonicity
    # Use 'measure' field (the actual canonicity measure used in web interface)
    # IMPORTANT: Order from MOST significant to LEAST significant for delta algorithm
    base_query = Work.joins(:attrs).where.not(work_attrs: {obsolete: true})
    
    # Add canonicity filter if specified (using 'measure' field)
    if @min_canonicity
      base_query = base_query.where('measure >= ?', @min_canonicity)
    end
    
    # Order by measure (canonicity) - DESC order ensures most significant works first
    # This matches the web interface ordering at /works
    base_query.order(measure: :desc, linkcount: :desc, id: :asc)
            .limit(@max_works)
  end
  
  def select_by_linkcount
    # Order from MOST significant (highest linkcount) to LEAST significant
    # This ensures the delta algorithm processes works in proper significance order
    Work.joins(:attrs).where.not(work_attrs: {obsolete: true})
        .order(linkcount: :desc, id: :asc)
        .limit(@max_works)
  end
  
  def select_by_mixed_ranking
    # Combine measure (canonicity) and linkcount with weighted scoring
    # CRITICAL: Order from HIGHEST mixed score to LOWEST (most to least significant)
    # Normalize measure and linkcount, then combine
    Work.joins(:attrs).where.not(work_attrs: {obsolete: true})
        .select('works.*, (measure * 0.6 + (linkcount::float / (SELECT MAX(linkcount) FROM shadows WHERE type = \'Work\')) * 0.4) as mixed_score')
        .order('mixed_score DESC, id ASC')
        .limit(@max_works)
  end
  
  def select_randomly
    Work.joins(:attrs).where.not(work_attrs: {obsolete: true})
        .order('RANDOM()')
        .limit(@max_works)
  end
  
  def select_recent_additions
    Work.joins(:attrs).where.not(work_attrs: {obsolete: true})
        .order(created_at: :desc)
        .limit(@max_works)
  end
  
  def extract_file_paths(works)
    works.map do |work|
      file_path = work.text&.fyle&.local_file
      if file_path && !file_path.start_with?('/')
        # Convert relative path to absolute path
        File.join(Rails.root, file_path)
      else
        file_path
      end
    end
  end
  
  def work_philosophers(work)
    if work.respond_to?(:creators)
      work.creators.joins(:names)
          .where(names: { lang: 'en' })
          .pluck('names.label')
          .uniq
    else
      []
    end
  end
  
  # Class methods for easy access to common configurations
  
  def self.by_canonicity(min_canonicity: nil, max_works: 50, **args)
    new(
      work_selection_strategy: :canonicity,
      min_canonicity: min_canonicity,
      max_works: max_works,
      **args
    )
  end
  
  def self.by_linkcount(max_works: 50, **args)
    new(
      work_selection_strategy: :linkcount,
      max_works: max_works,
      **args
    )
  end
  
  def self.mixed_ranking(max_works: 50, **args)
    new(
      work_selection_strategy: :mixed,
      max_works: max_works,
      **args
    )
  end
  
  def self.random_sample(max_works: 20, **args)
    new(
      work_selection_strategy: :random,
      max_works: max_works,
      **args
    )
  end
  
  private
  
  # Get the text file path for a work
  # This requires complex joins: Work → Author → Text → Fyle
  def get_text_file_path(work)
    # Find the first available text file for this work
    # Work → Expression → Philosopher (as Author) → Writing → Text → Fyle
    
    # Get all texts associated with this work's authors
    text_files = []
    
    work.creators.each do |philosopher|
      # Find corresponding Fyle records by matching author english name
      # Note: The authors table doesn't have wikidata_id, only english_name
      fyles = Fyle.joins(text: { writings: :author })
                  .where('fyles.local_file IS NOT NULL')
                  .where('authors.english_name = ?', philosopher.english)
      
      fyles.each do |fyle|
        file_path = fyle.absolute_local_file_path
        if file_path && File.exist?(file_path)
          text_files << file_path
          break # Use first available file
        end
      end
    end
    
    # Return first available file, or nil if none found
    text_files.first
  end
  
  # Extract text files for processing in significance order
  def extract_text_files_for_processing(works)
    text_files = []
    works_without_files = []
    
    works.each do |work|
      file_path = get_text_file_path(work)
      if file_path && File.exist?(file_path)
        text_files << {
          path: file_path,
          work: work,
          significance: work.measure || 0,
          linkcount: work.linkcount || 0
        }
      else
        works_without_files << work
      end
    end
    
    # Log statistics
    Rails.logger.info "Delta Analysis: Found #{text_files.size} text files for #{works.size} works"
    Rails.logger.info "Delta Analysis: #{works_without_files.size} works without accessible text files"
    
    if works_without_files.any?
      Rails.logger.warn "Works without text files: #{works_without_files.map(&:english).join(', ')}"
    end
    
    # Return only file paths in significance order (already ordered by work selection)
    text_files.map { |tf| tf[:path] }
  end
  
  # Get philosophers (creators) associated with a work
  def work_philosophers(work)
    work.creators.map(&:english).compact
  end
  
  # Generate incremental Saffron JSON corpus files for delta analysis
  # Creates corpus_1.json, corpus_2.json, corpus_3.json, etc.
  def generate_incremental_saffron_corpora(works_with_files, saffron_temp_dir)
    corpus_files = []
    
    works_with_files.each_with_index do |work_data, index|
      corpus_size = index + 1
      corpus_file = File.join(saffron_temp_dir, 'corpora', "corpus_#{corpus_size}.json")
      
      # Create corpus with works 1 through current index (cumulative)
      corpus_data = {
        documents: []
      }
      
      works_with_files[0..index].each_with_index do |work_file_data, doc_index|
        work = work_file_data[:work]
        file_path = work_file_data[:file_path]
        
        # Create document entry for Saffron JSON format
        authors = work.creators.map do |philosopher|
          {
            name: philosopher.english,
            id: "Q#{philosopher.entity_id}"
          }
        end
        
        document = {
          id: "work_#{work.id}",
          name: work.english || work.what_label || "Work #{work.id}",
          file: file_path,
          authors: authors,
          metadata: {
            entity_id: "Q#{work.entity_id}",
            measure: work.measure,
            linkcount: work.linkcount,
            significance_rank: doc_index + 1,
            corpus_position: doc_index + 1,
            total_in_corpus: corpus_size
          }
        }
        
        corpus_data[:documents] << document
      end
      
      # Write incremental corpus JSON file
      File.write(corpus_file, JSON.pretty_generate(corpus_data))
      corpus_files << corpus_file
      
      Rails.logger.info "Generated corpus_#{corpus_size}.json: #{corpus_data[:documents].length} documents"
    end
    
    corpus_files
  end
  
  # Create timestamped temporary directory for Saffron processing
  def create_saffron_temp_dir
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    temp_dir = Rails.root.join('tmp', 'saffron_analysis', "run_#{timestamp}")
    FileUtils.mkdir_p(temp_dir)
    
    # Create subdirs for organization
    FileUtils.mkdir_p(File.join(temp_dir, 'corpora'))        # JSON corpus files
    FileUtils.mkdir_p(File.join(temp_dir, 'saffron_output'))  # Saffron results
    FileUtils.mkdir_p(File.join(temp_dir, 'delta_reports'))   # Delta analysis reports
    
    temp_dir
  end
  
  # Prepare works with their corresponding text files
  def prepare_works_with_files(works)
    works_with_files = []
    
    works.each do |work|
      file_path = get_text_file_path(work)
      if file_path && File.exist?(file_path)
        works_with_files << {
          work: work,
          file_path: file_path
        }
      else
        Rails.logger.warn "No accessible text file found for work: #{work.english || work.what_label || work.id}"
      end
    end
    
    Rails.logger.info "Prepared #{works_with_files.length} works with accessible text files"
    works_with_files
  end
end