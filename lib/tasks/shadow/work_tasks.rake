# frozen_string_literal: true

require_relative '../utilities'
require_relative '../../wikidata/client_helpers'
require_relative '../../wikidata/sparql_queries'
require_relative '../../wikidata/query_executor'
require_relative '../../knowledge'

begin
  include TaskUtilities
  include Wikidata::ClientHelpers
  include Wikidata::SparqlQueries

  FORCE = true

  namespace :shadow do
    namespace :work do

      # == Show Philosophical Works
      #
      # Explores and displays philosophical works from Wikidata using targeted SPARQL queries.
      # Provides exploratory access to work data for analysis and potential import decisions.
      #
      # @param cond [String] Query strategy:
      #   - "authored_by_philosophers" - Works by philosophers (authored/notable works)
      #   - "of_philosophical_type" - Works classified as philosophical
      # @param arbitrary [String, nil] If provided, shows count only; if "-1", shows raw SPARQL query
      # @return [void] Outputs work information, count, or raw query to console
      #
      # == What it does:
      # 1. Validates query condition parameter
      # 2. If arbitrary parameter is "-1", prints raw SPARQL query and exits
      # 3. Executes appropriate Wikidata SPARQL query via Wikidata::QueryExecutor
      # 4. If arbitrary parameter provided: displays result count
      # 5. If no arbitrary parameter: displays full work information using show_work_stuff()
      # 6. Handles errors with structured logging via barf() utility
      #
      # == Query Strategies:
      #
      # === authored_by_philosophers:
      # - SPARQL: THESE_WORKS_BY_PHILOSOPHERS (finds works by philosophers)
      # - Includes authored works (P50) and notable works (P800)
      # - Filters out non-philosophical content (visual arts, TED talks, editions)
      # - Provides link counts as significance measure
      #
      # === of_philosophical_type:
      # - SPARQL: THESE_PHILOSOPHICAL_WORKS (philosophical genre classification)
      # - Uses genre hierarchy (Q5891 = philosophy and sub-genres)
      # - Includes works with philosophical subject classifications
      #
      # == Examples:
      #   bin/rake shadow:work:show[authored_by_philosophers]
      #   # => Displays detailed listings of works by philosophers
      #
      #   bin/rake shadow:work:show[of_philosophical_type,true]
      #   # => Shows count: Got 1,247 of 'em
      #
      #   bin/rake shadow:work:show[authored_by_philosophers,-1]
      #   # => Prints raw SPARQL query and exits
      #
      # == Used by:
      # - Data exploration before running shadow:work:populate
      # - Research into available philosophical works in Wikidata
      # - Debugging work discovery and classification logic
      # - SPARQL query development and testing
      #
      # == Performance Notes:
      # - SPARQL queries can take 30-90 seconds depending on Wikidata load
      # - Results cached by Wikidata::QueryExecutor for repeated calls
      # - Count mode faster than detail mode (no show_work_stuff processing)
      #
      # == Error Handling:
      # - Invalid conditions show usage help
      # - Wikidata timeouts automatically retried by QueryExecutor
      # - Exceptions logged with context via barf() utility
      #
      # == Related Tasks:
      # - shadow:work:populate - Imports discovered works into database
      # - shadow:work:connect - Links works to existing texts
      # - shadow:work:describe - Shows work metadata and relationships
      #
      desc "Query Wikidata for philosophical works ([authored_by_philosophers|of_philosophical_type][,arbitrary])"
      task :show, [:cond,:arbitrary] => :environment do |task, arg|
        begin
          require 'knowledge'
          include Knowledge
          # w = Knowledge::Wikidata::Client.new
          show = nil
          case arg.cond
            #
          when "authored_by_philosophers"
            q = THESE_WORKS_BY_PHILOSOPHERS.gsub("\t",'')
            if arg.arbitrary.to_i < 0
              puts THESE_WORKS_BY_PHILOSOPHERS
              exit
            end
            puts "About to execute query for works by philosophers..."
            res = Wikidata::QueryExecutor.execute(q, 'authored_by_philosophers', {
              task_name: 'shadow:work:query'
            })
          when "of_philosophical_type"
            q = THESE_PHILOSOPHICAL_WORKS.gsub("\t",'')
            if arg.arbitrary.to_i < 0
              puts THESE_PHILOSOPHICAL_WORKS
              exit
            end
            puts "About to execute query for works of philosophical type..."
            res = Wikidata::QueryExecutor.execute(q, 'of_philosophical_type', {
              task_name: 'shadow:work:query'
            })
          else
            puts "No condition specified. Available conditions: authored_by_philosophers, of_philosophical_type"
            puts "Usage: bin/rake shadow:work:show[authored_by_philosophers] or bin/rake shadow:work:show[of_philosophical_type]"
            res = []
          end
          if arg.arbitrary
            # p arg
            # puts "arbitrary#inspect: #{arg.arbitrary.inspect}"
            # puts "arbitrary#class: #{arg.arbitrary.class}"
            # puts "non_existent_param#inspect: #{arg.non_existent_param.inspect}"
            puts "Got #{res.size} of 'em"
          else
            show_work_stuff(res)
          end
        rescue
          barf $!, 'work:show urk'
        end
      end

      # == Connect Works and Texts Task
      #
      # This task establishes connections between philosophical works and their corresponding
      # text files in the database. It performs name-based matching to link Work records
      # with Text records that contain the actual content.
      #
      # == What it does:
      # 1. Iterates through all philosophers ordered by their canonicity measure (most significant first)
      # 2. For each philosopher, finds all their associated works through the Expression join table
      # 3. For each work, attempts to find matching Text records by comparing work names/labels
      # 4. Also finds texts through the Author -> Writing -> Text relationship chain
      # 5. Outputs the connections found, showing which works have accessible text files
      #
      # == Matching logic:
      # - Uses work.label or work.name_hack (with SQL escaping for apostrophes)
      # - Performs exact name matching against Text.name_in_english field
      # - Also connects through author relationships for additional text discovery
      #
      # == Output format:
      # For each philosopher with connections:
      # - Lists work-text matches with text names and file IDs
      # - Shows summary: "==> Q{entity_id} ({works_found}/{texts_found})"
      # - Uses "===" separator for works with direct matches
      # - Displays progress bar during execution
      # - Logs all output to log/task_output.log
      #
      # == Purpose:
      # This task helps identify which philosophical works in the database have corresponding
      # text files available, supporting the delta analysis and text processing pipeline.
      #
      # == Performance note:
      # Processes all philosophers and their works, which could be time-consuming for large datasets.
      # Includes progress tracking and comprehensive logging.
      #
      # == Invocation:
      # This task takes no parameters. Run it with:
      #   bin/rake shadow:work:connect
      #
      desc "Link philosophical works to available text files (name matching + author relationships)"
      task connect: :environment do
        Shadow.none
        phils = Philosopher.order(measure: :desc)
        en_phils = phils.select('shadows.*, names.lang, names.label').joins(:names).where('names.lang =?', 'en')
        
        # Set up progress bar and logging
        total = en_phils.length
        bar = progress_bar(total, FORCE, '', 'connecting works to texts')
        log_file = File.open('log/task_output.log', 'a')
        log_file.puts("\n=== Work-Text Connection Task Started: #{Time.now} ===")
        
        en_phils.each {|phil|
          works = Work.where(id: Expression.where(creator_id: phil.id).pluck(:work_id)).order('linkcount desc')
          en_works = works.select('shadows.*, names.lang, names.label').joins(:names).where('names.lang =?', 'en')
          found = 0
          en_works.each do|work|
            label = work.name_hack.nil? ? work.label : work.name_hack # very hacky
            the_text = ::Text.where("name_in_english LIKE '"+label.gsub("'", "''")+"'").first
            if the_text.nil?
            else
              output = "'#{the_text.name_in_english}' #{the_text.fyle_id}"
              log_file.puts(output)
              found += 1
            end
          end
          if found > 0
            separator = "==="
            log_file.puts(separator)
          end
          texts = ::Text.where(id: Writing.where(author_id: Author.where(english_name: phil.label)).pluck(:text_id))
          texts.each do|text|
            output = "'#{text.name_in_english}' #{text.fyle_id}"
            log_file.puts(output)
          end
          if found > 0 or texts.count > 0
            summary = "==> Q#{phil.entity_id} (#{found}/#{texts.count})"
            log_file.puts(summary)
          end
          
          update_progress(bar)
        }
        
        log_file.puts("=== Work-Text Connection Task Completed: #{Time.now} ===")
        log_file.close
      end

      # 
      # at the moment there are many deficincies with works
      #
      # (1) anonymous works and works whose author(s) are contested
      #     philosophical works of unknown authorial provenance
      #     you get the idea
      # (2) philosophical works by non-philosophers
      #     cus we track/anchor with philosophers which is wrong
      #
      # == Deez Wurks Method
      #
      # Core method for populating the works database from Wikidata SPARQL queries.
      # Processes philosopher-work relationships and creates Work and Expression records.
      #
      # @param q [String] The SPARQL query string to execute
      # @return [void]
      #
      # == What it does:
      # 1. Executes the provided SPARQL query against Wikidata
      # 2. For each result, extracts philosopher and work entity IDs
      # 3. Creates Work records if they don't exist (with linkcount metadata)
      # 4. Creates Expression records linking philosophers to their works
      # 5. Handles duplicate records gracefully
      #
      # == Used by:
      # - shadow:work:populate[works1]
      # - shadow:work:populate[works2]
      #
      # == Error handling:
      # - Skips philosophers that don't exist in the local database
      # - Handles ActiveRecord::RecordNotUnique exceptions for duplicate works
      # - Continues processing even if individual expressions fail to save
      #
      def deez_wurks(q)
        Shadow.none
        require_relative '../../wikidata/query_executor'
        puts q
        res = Wikidata::QueryExecutor.execute_simple(q, 'deez_wurks', {
          task_name: 'shadow:work:deez_wurks'
        })
        # bar = progress_bar(res.length, FORCE)
        bar = progress_bar(res.length)
        mult = [] # only used to suppress output
        res.each_with_index do |val, idx|
          phil       = val.bindings[:item]
          work       = val.bindings[:work]
          name       = val.bindings[:workLabel].to_s
          #what       = val.bindings[:whatLabel].to_s
          #viaf       = val.bindings[:viaf].nil? ? nil : val.bindings[:viaf].to_s
          count      = val.bindings[:linkCount].to_i
          p_entity = phil.to_s.split('entity/').last
          w_entity = work.to_s.split('entity/').last
          p_e      = p_entity[1..-1]
          p = Philosopher.where(entity_id: p_e.to_i).first
          if p.nil?
            if not mult.include?(p_e)
              mult.push(p_e)
              puts "Can't find philosopher with Q#{p_e} for #{name}"
            end
          else
            w_e = w_entity[1..-1]
            #w = Work.new(entity_id: w_e.to_i, viaf: viaf ,linkcount: count, what_label: what)
            w = Work.new(entity_id: w_e.to_i, linkcount: count)
            begin
              w.save!
              puts name
            rescue ActiveRecord::RecordNotUnique
              w = Work.where(entity_id: w_e.to_i).first
            end
            e = Expression.compose(p,w) # 
            begin
              e.save!
              p e
            rescue
            end
          end
          #update_progress(bar)
        end
      end

      desc "SPARQLy textual investigations       ([/^Q\d+/]  or  [/^d+/])"
      task :work_labels, [:cond, :execute] => :environment do |task, arg|
        begin
          puts "execute: #{arg.execute.inspect}"
          case arg.cond
            # get all the labels for each work for a particular philosopher's works
            # (used as you're moving on down the list)
          when /^Q\d+/
            Shadow.none
            works = Philosopher.find_by(entity_id: arg.cond[1..-1]).works.where.not(obsolete: true)
            works.each do |w|
              update_labels(w)
            end
            puts "#{works.length} records in total"
            langorder(FORCE, works.pluck(:id))
          when /^\d+/
            #works = Work.where(id: Expression.where(creator_id: arg.cond.to_i).pluck(:work_id))
            #pp works
            Shadow.none
            works = Philosopher.find(arg.cond).works.where.not(obsolete: true)
            works.each do |w|
              update_labels(w)
            end
            puts "#{works.length} records in total"
            langorder(FORCE, works.pluck(:id))
          else
          end
        rescue StandardError => e
          barf e, 'work:labels urk'
        end
      end

      desc "SPARQLy textual investigations       (set genre)"
      task :signal3 => :environment do |task, arg|
        begin
          Shadow.none
          require 'knowledge'
          include Knowledge
          require_relative '../../wikidata/query_executor'
          q = THESE_PHILOSOPHICAL_WORKS.gsub("\t",'')
          puts q
          solution_set = Wikidata::QueryExecutor.execute(q, 'philosophical_works_populate', {
            task_name: 'shadow:work:populate'
          })
          bar = progress_bar(solution_set.length)
          solution_set.each { |solution|
            work   = solution.bindings[:work]
            name   = solution.bindings[:workLabel].to_s
            entity = work.to_s.split('/').last
            entity_id = entity[1..-1].to_i
            begin
              work = Work.find_by!(entity_id: entity_id)
              work.genre = true
              work.save!
            rescue ActiveRecord::RecordNotFound
              if entity == name
                puts "FIXME: Work w/ entity id #{entity_id} is not in the db, prolly no author."
              else
                puts "FIXME: Work "#{name}" w/ entity id #{entity_id} is not in the db, prolly no author."
              end
            end
            # update_progress(bar)
          }
        rescue StandardError => e
          barf e, 'work:snarf urk'
        end
      end

      desc "SPARQLy textual investigations       ([works1] [works2])"
      task :populate, [:cond] => :environment do |task, arg|
        begin
          case arg.cond
            #
          when "works1"
            q = THESE_WORKS_BY_PHILOSOPHERS.gsub("\t",'')
            deez_wurks(q)
          when "works2"
            q = THESE_PHILOSOPHICAL_WORKS.gsub("\t",'')
            deez_wurks(q)
          else
            puts 'Work it baby!'
          end
        rescue StandardError => e
          barf e, 'work:snarf urk'
        end
      end

      # == Describe Works Task
      #
      # This task performs exploratory data analysis on Wikidata properties used across all works
      # in the database. It analyzes what predicates (properties/relationships) are commonly used
      # in Wikidata for philosophical works.
      #
      # == What it does:
      # 1. Iterates through all Work records in the database (ordered by default, likely by ID)
      # 2. For each work, executes a SPARQL DESCRIBE query against Wikidata for that work's entity
      #    (e.g., DESCRIBE wd:Q12345 where 12345 is the work's entity_id)
      # 3. Collects all predicates (properties/relationships) that appear in the Wikidata descriptions
      # 4. Counts frequency of each predicate across all works
      # 5. Outputs a summary showing how many works use each predicate, grouped by frequency
      #
      # == Output format:
      # Prints a hash like {count => [predicate1, predicate2, ...]} sorted by count, showing which
      # Wikidata properties are most commonly used across your philosophical works dataset.
      #
      # == Purpose:
      # This is an exploratory/data profiling task to understand what types of metadata and
      # relationships exist in Wikidata for the works in your database, helping identify which
      # properties might be useful for further processing or analysis.
      #
      # == Performance note:
      # This task makes one SPARQL query per work (potentially thousands of HTTP requests to Wikidata),
      # so it could take a significant amount of time to run on a large dataset. The code includes
      # progress bars and error handling.
      #
      # == Invocation:
      # This task optionally takes a count parameter to limit the number of works processed.
      #   bin/rake shadow:work:describe          # Process all works
      #   bin/rake shadow:work:describe[100]     # Process first 100 works only
      #
      desc "Analyze Wikidata properties used across philosophical works ([count])"
      task :describe, [:the_count] => :environment do |task, arg|
        the_count = (arg.count>0) ? arg.the_count&.to_i : nil
        predicates = {}
        one_by_one(:describe, "DESCRIBE wd:Q%{interpolated_entity}", {}, the_count) {|solution_set|
          tmp = {}
          solution_set.each do|solution|
            p = solution.predicate.to_s
            tmp[p] = true
          end
          tmp.keys.each do|p|
            begin
              predicates[p] = predicates[p]+1
            rescue NoMethodError
              predicates[p] = 1
            end
          end
        }
        p predicates.each_with_object({}){|(k,v),o|(o[v]||=[]).push(k)}.sort.to_h
      end

      desc "expunge works we definitely do not want"
      task expunge: :environment do
        get_rid = [
          'Q3331189',  # edition
          'Q483372',   # paradox
          'Q35127',    # website
          'Q179461',   # religious text ?
          'Q3985225',  # rabbinic lit.
          'Q23691',    # national anthem (i kid thee not)
          'Q27560760', # collection of fairy tales
          'Q93184',    # drawing
          'Q3918409',  # proposal
          'Q5551960',  # germanic mythology
          'Q12308638', # poetry collection ?
          'Q52947181', # public statement
          'Q37484',    # epic poem ?
        ]
        as_ever = 'SELECT ?p WHERE {'+(get_rid.collect{|what| "OPTIONAL {wd:Q%{interpolated_entity} ?p wd:#{what}.}"}.join(' '))+'}'
        one_by_one(:expunge, as_ever, {linkcount: :asc}) {|solution_set, work|
          if 0 != solution_set.first.count
            work.obsolete = true
            work.save!
          end
        }
      end

      desc "get britannica and philpapers signal"
      task signal1: :environment do |task, arg|
        begin
          Shadow.none
          works = Work.where.not(obsolete: true).order(measure: :desc).limit(500)
          exit if works.nil?
          total = works.length
          bar = progress_bar(total, FORCE)
          works.each {|work|
            attrs = properties("Q#{work.entity_id}")
            # these are for philosophical figure, remove 'em
            attrs.delete(:floruit)
            attrs.delete(:gender)
            attrs.delete(:period)
            attrs.delete(:births)
            attrs.delete(:deaths)
            attrs.delete(:citizen)
            # these are not handled yet, remove 'em
            attrs.delete(:title)
            q="Q#{work.entity_id}".ljust(9)
            do_date(q, attrs, :pub_date)
            work.pub = attrs[:pub_date]
            pub_year = work.year(:pub)
            attrs[:pub_year] = pub_year
            attrs[:pub_approx] = work.pub_approx
            work.update_attributes(attrs)
            update_progress(bar)
          }
        rescue StandardError => e
          barf e, 'work:signal urk'
        end
      end

      desc "SPARQLy textual investigations (of the order2ing variety)"
      task order2: :environment do
        Shadow.none

        # Update measure_pos based on current measure values in shadow table
        works = Work.order('measure desc').group(:measure)
        work_groupings = works.count
        num_work_blocks = work_groupings.length
        bar = progress_bar(num_work_blocks, FORCE, 'groups of records')
        work_groupings.each_with_index do |measure, idx|
          Work.where(measure: measure[0]).update_all(measure_pos: idx+1)
          update_progress(bar)
        end

        # Also update measure_pos in latest snapshots for each work
        puts "Updating measure_pos in metric snapshots..."
        snapshot_bar = progress_bar(Work.count, FORCE, '', 'updating snapshots')
        Work.find_each do |work|
          latest_snapshot = work.metric_snapshots.order(calculated_at: :desc).first
          if latest_snapshot && latest_snapshot.measure_pos != work.measure_pos
            latest_snapshot.update(measure_pos: work.measure_pos)
          end
          update_progress(snapshot_bar)
        end
      end

      desc "SPARQLy textual investigations (of the measureful variety)"
      task measure: :environment do
        Shadow.none

        # Phase 1: Update encyclopedia flags from works.json
        if File.exist?('works.json')
          File.open('works.json'){|f|
            json_works = f.read
            works = JSON.parse(json_works)
            total = works.length
            bar = progress_bar(total, FORCE, 'updating encyclopedia flags')
            works.each do |work|
              w = Work.find_by(entity_id: work[0])
              w.cambridge = ('y' == work[2])
              w.borchert = ('y' == work[3])
              w.routledge = ('y' == work[4])
              w.save!
              update_progress(bar)
            end
          }
        else
          puts "Warning: works.json not found, skipping encyclopedia flag updates"
        end

        # Phase 2: Calculate canonicity measures using new method
        total = Work.all.size
        bar = progress_bar(total, FORCE, 'calculating measures')

        danker_info = {
          version: 'current',
          file: 'calculated_from_shadow_work_measure_task'
        }

        Work.order(:entity_id).each do |work|
          # Use the new calculate_canonicity_measure method
          normalized_measure = work.calculate_canonicity_measure(
            algorithm_version: '2.0-work',
            danker_info: danker_info
          )

          # Also update the shadow record for backward compatibility
          # The method already creates a snapshot, so we just update the measure field
          raw_measure = normalized_measure * (work.genre ? 1.0 : 0.5) * 1_000_000
          work.update(measure: raw_measure)

          q = "Q#{work.entity_id}".ljust(9)
          update_progress(bar, "#{q} #{raw_measure.round(2)}")
        end

        null_point = Work.where(measure: 0.0).size
        puts "Null point is #{null_point}, usable works is #{total-null_point}"
        puts "Created #{MetricSnapshot.for_works.count} work snapshots"
      end

      desc "SPARQLy textual investigations (of the mentioning variety)"
      task signal2: :environment do |task, arg|
        Shadow.none
        works = Work.all
        exit if works.nil?
        count = 0
        begin
          start = File.read('tmp/.work_mention').to_i
          if arg.cond.nil?  
            puts "Must supply at starting index value from where it was interrupted."
            exit
          else
            from = arg.cond.to_i
            if from < 0 or from > works.size
              puts "The starting index value is out of range."
              exit
            end
          end
        rescue
          puts "resetting values"
          works.update_all(philosophy: 0, philosophical: 0)
        end
        filters { |filter1, filter2, filter3|
          puts "round: #{count}"
          if count >= start
            bar = progress_bar(works.size, true)
            works.each_with_index do |work, idx|
              if idx < from
                continue
              end
              acc = mention_one(work.entity_id, [filter1,filter3])
              if acc.sum > 0
                entity = "Q#{work.entity_id}"
                puts "#{entity.ljust(8)} #{work.linkcount.to_s.ljust(3)} (philosophy #{acc[0]} + philosophical #{acc[1]}) -= #{acc.sum}" if bar.nil?
                attrs = {philosophy: acc[0]-work.philosophy.to_i, philosophical: acc[1]-work.philosophical.to_i}
                work.update_attributes(attrs)
              end
              update_progress(bar)
            end
            GC.start
            File.write('tmp/.work_mention',count+1)
            from = 0
          end
          count += 1
        }
        total = works.update_all('mention = (philosophy + philosophical)')
        File.unlink('tmp/.work_mention')
      end

      # == VIAF Work Population Task
      #
      # Populates the works database by fetching philosopher works from VIAF (Virtual International
      # Authority File) using Wikidata as an intermediary to obtain VIAF identifiers.
      #
      # @param cond [String] Processing scope:
      #   - Numeric VIAF ID: Process only the philosopher with that VIAF ID
      #   - Empty/omitted: Process all philosophers ordered by canonicity measure
      # @return [void] Outputs processing results and statistics to console
      #
      # == What it does:
      # 1. Determines processing scope (single philosopher or all philosophers)
      # 2. For each philosopher, queries Wikidata to retrieve VIAF identifiers
      # 3. Updates philosopher records with VIAF ID information
      # 4. Fetches VIAF XML data for each VIAF identifier
      # 5. Parses VIAF data to extract work information and create Work records
      # 6. Creates Expression records linking philosophers to their discovered works
      # 7. Provides detailed statistics on works found vs existing works
      #
      # == Data Flow:
      # Philosopher (local DB) → Wikidata query → VIAF IDs → VIAF XML → Works → Expressions
      #
      # == Processing Logic:
      # - Single philosopher mode: arg.cond matches /^\d+/ (VIAF ID lookup)
      # - Bulk mode: Process all philosophers ordered by measure (most significant first)
      # - VIAF deduplication: @work_once array prevents processing same work multiple times
      # - Error handling: Continues processing even if individual operations fail
      #
      # == Output Format:
      # - Progress: [PhilosopherName:VIAF_ID] for each VIAF being processed
      # - Success: "+ Expression" for each work-philosopher link created
      # - Statistics: "X total - Y unique = Z left over" (existing vs newly found works)
      # - Missing works: Lists high-measure works not found in VIAF data
      #
      # == External Dependencies:
      # - Wikidata SPARQL endpoint for VIAF ID retrieval
      # - VIAF XML API for work metadata
      # - Network connectivity to both services
      #
      # == Performance Notes:
      # - Makes multiple HTTP requests per philosopher (Wikidata + VIAF)
      # - Processes philosophers sequentially (no parallelization)
      # - Includes garbage collection between philosophers to manage memory
      # - Can be time-intensive for large philosopher datasets
      #
      # == Examples:
      #   bin/rake shadow:work:viaf[123456789]    # Process philosopher with VIAF ID 123456789
      #   bin/rake shadow:work:viaf               # Process all philosophers
      #
      # == Used by:
      # - Work database population and enrichment
      # - Linking philosophers to their bibliographic works
      # - Complementing Wikidata-based work discovery with VIAF data
      #
      # == Error Handling:
      # - Continues processing if VIAF queries fail
      # - Handles missing philosopher records gracefully
      # - Reports but doesn't fail on work creation conflicts
      #
      desc "populate Work (works table) using philosopher Viaf data"
      task :by_viaf, [:viaf] => :environment do |task, arg|
        Shadow.none
        case arg.viaf
        when /^\d+/ # either singly
          phils = [Philosopher.find_by(viaf: arg.viaf)]
        else
          phils = Philosopher.all.order(measure: :desc)
        end

        require 'knowledge'
        include Knowledge
        # w = Knowledge::Wikidata::Client.new
        require 'net/http'

        phils.each {|phil|
          entity = "Q#{phil.entity_id}"
          begin
            substitution_hash = {interpolated_entity: entity}
            res = interpolated_entity(ATTR_, substitution_hash)
            if 1 < res.length
              Rails.logger.info "res.length > 1 for entity:#{entity} → res:#{res.inspect}"
              viaf_ids = res.bindings[:viaf].collect{|v|v.to_s}.uniq
            elsif 0 == res.length
              next
            else
              viaf_ids = [res.bindings[:viaf].first.to_s]
            end
          end
          phil.viaf = viaf_ids.join(':')
          phil.save!
          work_qs = []
          label = phil.english
          @work_once = [
            '180971400', # Nicomachean ethics. Book 6.
            '305105455', # Nicomachean ethics. Book 10.
            '309516325', # Nicomachean ethics. Book 2-4.
            '309546615', # De caelo. Liber 3.
            '309558007', # Metaphysics. Book M.
            '309558008', # Metaphysics. Book N.
            '309553444', # Politics. Books 3-4.
            '309554420', # Grundlegung zur Metaphysik der Sitten. 2.
            '5669151051954733530003', # Meditationes de prima philosophia. 2. Selections.
            '178970449', # Q371884/Timaeus – redirects to '269728865'
            '220008331', # Q1180623/De fato – doesn't redirect, but should? '315944581'
            '2698149619368004010005', # Tusculanae disputationes. Selections (Davie)
            '309482297', # Summa theologica. Pars 1. Quaestio 75-88.
            '315937978', # Wallenstein. Wallensteins Tod. 
          ]
          viaf_ids.each do |viaf_id|
            puts "[#{label}:#{viaf_id}]"
            str = viaf_url(viaf_id)
            parse_viaf(str) do |work|
              begin
                e = Expression.new(creator_id: phil.id, work_id: work.id)
                e.save!
                puts "+ #{e}"
              rescue
              end
              work_qs.push(work.entity_id)
            end
          end
          work_qs = work_qs.uniq
          plucked_qs = phil.creations.pluck(:entity_id)
          left_overs = plucked_qs-work_qs
          puts "#{plucked_qs.length} total - #{work_qs.length} unique = #{left_overs.length} left over"
          left_overs.each do |e_id|
            match = Work.find_by(entity_id: e_id)
            if match.measure > 0.0
              begin
                unless match.viaf.present?
                  puts "#{match.viaf.to_s.ljust(27)} => [#{sprintf("%.3f",match.measure).rjust(9)}] #{match.english} :- http://www.wikidata.org/entity/Q#{match.entity_id}"
                end
              rescue
                puts "#{match.viaf.to_s.ljust(27)} => [#{sprintf("%.3f",match.measure).rjust(9)}] [] :- http://www.wikidata.org/entity/Q#{match.entity_id}"
              end
            end
          end
          GC.start
        }
      end

      # == One By One Method
      #
      # Utility method for iterating through all Work records and executing SPARQL queries
      # against Wikidata for each work. Provides progress tracking and error handling.
      #
      # @param task [String] Task name for logging purposes
      # @param query_str [String] SPARQL query template with %{interpolated_entity} placeholder
      # @param in_order [Hash] Ordering options for Work records (default: {})
      # @param limit [Integer, nil] Maximum number of works to process (default: nil = all)
      # @yield [solution_set, work] Block executed for each work with query results
      # @yieldparam solution_set [Array] SPARQL query results for this work
      # @yieldparam work [Work] The current Work record being processed
      # @return [void]
      #
      # == What it does:
      # 1. Retrieves all Work records (optionally limited and ordered)
      # 2. For each work, interpolates its entity_id into the query template
      # 3. Executes the SPARQL query against Wikidata
      # 4. Yields the results and work record to the provided block
      # 5. Shows progress bar and handles errors gracefully
      #
      # == Used by:
      # - shadow:work:describe
      # - shadow:work:expunge
      #
      # == Progress tracking:
      # Displays a progress bar showing completion percentage and estimated time remaining.
      #
      def one_by_one(task, query_str, in_order={}, limit=nil)
        begin
          Shadow.none
          works_query = Work.order(in_order)
          works_query = works_query.limit(limit) if limit
          works = works_query
          exit if works.nil?
          total = works.length
          bar = progress_bar(total, true)
          require_relative '../../wikidata/query_executor'
          works.each {|work|
            q = query_str % {:interpolated_entity => work.entity_id}
            solution_set = Wikidata::QueryExecutor.execute_simple(q, "work_#{work.entity_id}", {
              task_name: 'shadow:work:iterate'
            })
            yield solution_set, work
            update_progress(bar)
          }
        rescue
          barf $!, "work:#{task} urk"
          # binding.pry
        end
      end

      # == Truncate Method
      #
      # Utility method for shortening text labels to a specified length while preserving
      # word boundaries when possible. Used for display purposes in logging and output.
      #
      # @param label [String] The text to truncate
      # @param length [Integer] Maximum length of the truncated string
      # @param word_break [Boolean] Whether to break at word boundaries (default: true)
      # @return [String] The truncated string with "…" appended if truncation occurred
      #
      # == Behavior:
      # - If label is shorter than length, returns it unchanged
      # - If word_break is true, finds the last complete word that fits within length
      # - If word_break is false, truncates at the exact character position
      # - Always appends "…" when truncation occurs
      #
      # == Examples:
      #   truncate("The Republic", 10)     # => "The Republic"
      #   truncate("Critique of Pure Reason", 15, true)  # => "Critique of Pure…"
      #   truncate("Critique of Pure Reason", 15, false) # => "Critique of Pur…"
      #
      def truncate(label, length, word_break=true)
        if label.length > length
          parts = label.split
          len = 0
          str = ''
          i = 0
          parts.each_with_index{ |part,idx|
            break if (len+part.length) > length
            len += (part.length+1)
            str += (part+' ')
            i = idx+1
          }
          if word_break
            part = parts[i]
            str+(part[0..part.length/2])+'…'
          else
            str+' …'
          end
        else
          label
        end
      end

      def viaf_xml(id)
        "https://viaf.org/viaf/#{id}/viaf.xml"
      end

      def viaf_url(id)
        url = viaf_xml(id)
        uri = URI.parse(url)
        request = Net::HTTP::Get.new(uri.request_uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.start do |http|
          http.request(request)
        end
        response.body
      end

      def match_name(full_id, title, match)
        begin
          puts "#{full_id.ljust(27)} =@ [#{sprintf("%.3f",match.measure).rjust(9)}] #{truncate(title, 40)} :- Q#{match.entity_id}/#{match.english}"
        rescue
          puts "#{full_id.ljust(27)} =@ [#{sprintf("%.3f",match.measure).rjust(9)}] #{truncate(title, 40)} :- Q#{match.entity_id}/[]"
        end
      end

      def match_id(entity_id, full_id, viaf_id, title, url)
        begin
          work = Work.find_by! entity_id: entity_id
          if work.viaf.nil? or work.viaf.blank?
            work.viaf = viaf_id
            work.save!
          end
          begin
            #puts "#{full_id.ljust(27)} => [#{sprintf("%.3f",work.measure).rjust(9)}] #{truncate(title, 40)} :- Q#{entity_id}/#{work.english}"
          rescue
            puts "#{full_id.ljust(27)} => [#{sprintf("%.3f",work.measure).rjust(9)}] #{truncate(title, 40)} :- Q#{entity_id}/[]"
          end
        rescue ActiveRecord::RecordNotFound
          puts "#{full_id.ljust(27)} <= #{truncate(title, 40)} :- #{url}"
        end
        work
      end

      def match_neither(full_id)
        printf "#{full_id.ljust(27)}\r"
      end

      def parse_viaf(obj)
        doc = Nokogiri::XML(obj)
        require 'knowledge'
        include Knowledge
        endpoint = Knowledge::Wikidata::Client.new
        # Use namespace-agnostic XPath or search by local name
        works = doc.xpath('//work') || doc.xpath('//*[local-name()="work"]')
        puts "#{works.length} work(s)"
        personal = doc.xpath('//viafID').first || doc.xpath('//*[local-name()="viafID"]').first
        personal_content = personal ? personal.content : "unknown"
        puts "VIAF ID: #{personal_content}"
        works.each {|w|
          full_id = w["id"]
          node_set = w.xpath('title') || w.xpath('*[local-name()="title"]')
          title = node_set.first ? node_set.first.content : "Unknown Title"
          if full_id.nil?
          elsif full_id.empty?
          else
            parts = full_id.split('|')
            if 2 == parts.length
              if 'VIAF' == parts.first
                viaf_id = parts.second
                next if @work_once.include?(viaf_id)
                @work_once.push(viaf_id)
                vci_set = ViafCacheItem.where(personal: personal, uniform_title_work: viaf_id)
                if 1 == vci_set.length
                  vci = vci_set.first
                  if not vci.q.blank?
                    work = match_id(vci.q, full_id, viaf_id, title, vci.url)
                    yield work unless work.nil?
                  else
                    match_neither(full_id)
                  end
                  next
                elsif 1 < vci_set.length
                  raise "??? multiple Database hits yielding #{vci_set}"
                end
                q = "SELECT ?item WHERE { ?item wdt:P214 '#{viaf_id}' }"
                solutions = endpoint.query(q)
                len = solutions.length
                if 0 == len
                  str = viaf_url(viaf_id)
                  node = Nokogiri::XML(str)
                  expressions = node.xpath('//expression') || node.xpath('//*[local-name()="expression"]')
                  try_once = []
                  neither = true
                  expressions.each {|expr|
                    lang = ''
                    begin
                      lang = expr.xpath('lang').first || expr.xpath('*[local-name()="lang"]').first
                      lang = lang ? lang.content : ""
                    rescue
                      puts "0 #{$!}" 
                    end
                    if "English" == lang
                      begin
                        el = expr.xpath('title').first || expr.xpath('*[local-name()="title"]').first
                        break if el.nil?
                        title = el.content.split('.')[0]
                        next if try_once.include?(title)
                        try_once.push(title)
                        ids = Name.where('label LIKE ?', title).pluck(:shadow_id).uniq
                        matches = Work.where(id: ids).where.not(obsolete: true)
                        puts "1 (#{matches.length})"
                        raise "Aw hell #{full_id.ljust(27)} =! #{truncate(title, 40)} :- Q#{matches.collect{|m|m.entity_id}}/#{matches.collect{m|m.english}}" if matches.length > 1
                        break unless matches.each {|match|
                          if match.creators.collect{|m|m.viaf}.include?(personal)
                            neither = false
                            match_name(full_id, title, match)
                          end
                        }.empty?
                      rescue
                        puts "2 #{$!}"
                      end
                    end
                  }
                  if neither
                    match_neither(full_id)
                    ViafCacheItem.new(personal: personal, uniform_title_work: viaf_id, q: '', url: '').save!
                  end
                elsif 1 == len
                  solution = solutions.first
                  if 0 == (solution.item.to_s =~ /http:\/\/www.wikidata.org\/entity\/(.+)/)
                    entity_id = ($1)[1..-1]
                    url = solutions.first.item.to_s
                    work = match_id(entity_id, full_id, viaf_id, title, url)
                    yield work unless work.nil?
                    ViafCacheItem.new(personal: personal, uniform_title_work: viaf_id, q: entity_id, url: url).save!
                  else
                    raise "??? multiple Database hits for #{$1}"
                  end
                else
                  raise "??? multiple Wikidata hits for #{full_id}"
                end
              else
                raise "??? unrecognised identifier #{full_id}"
              end
            else
            end
          end
        }
      end

    end
  end

rescue StandardError => e
  barf e, 'shadow work tasks'
end