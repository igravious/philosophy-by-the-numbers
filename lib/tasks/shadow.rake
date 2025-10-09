begin
	require_relative '../knowledge'

	# SPARQL Query Logging Helper
	def log_sparql_query(query, method_name, context = {})
		timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
		
		# Console output if SPARQL_DEBUG is enabled
		if ENV['SPARQL_DEBUG'] == 'true'
			puts "\n" + "="*80
			puts "SPARQL Query Debug [#{timestamp}]"
			puts "Method: #{method_name}"
			puts "Context: #{context.inspect}" unless context.empty?
			puts "-" * 80
			puts query.gsub("\t", '  ') # Replace tabs with spaces for readability
			puts "="*80 + "\n"
		end
		
		# Always log to file (not just when SPARQL_LOG is enabled)
		log_dir = Rails.root.join('log')
		log_file = log_dir.join('sparql_queries.log')
		
		File.open(log_file, 'a') do |f|
			f.puts "\n[#{timestamp}] Method: #{method_name}"
			f.puts "Context: #{context.inspect}" unless context.empty?
			f.puts "Query:"
			f.puts query
			f.puts "-" * 80
		end
	rescue => e
		# Don't let logging errors break the main functionality
		puts "Warning: SPARQL logging failed: #{e.message}" if ENV['SPARQL_DEBUG'] == 'true'
	end

	# Enhanced logging for task output
	def log_task_output(message, method_name = 'task_output')
		timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
		
		# Always print to console
		# puts message
		
		# Always log to file
		log_dir = Rails.root.join('log')
		log_file = log_dir.join('sparql_queries.log')
		
		File.open(log_file, 'a') do |f|
			f.puts "[#{timestamp}] #{method_name}: #{message}"
		end
	rescue => e
		puts "Warning: Task logging failed: #{e.message}"
	end

	# Simple progress spinner/throbber
	class ProgressSpinner
		def initialize(message = "Processing")
			@message = message
			@chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
			@index = 0
			@thread = nil
			@start_time = Time.now
		end

		def start
			@start_time = Time.now
			@thread = Thread.new do
				loop do
					elapsed = Time.now - @start_time
					elapsed_str = format_time(elapsed)
					print "\r#{@message} #{elapsed_str} #{@chars[@index]}"
					@index = (@index + 1) % @chars.length
					sleep(0.08)
				end
			end
		end

		def stop(final_message = nil)
			@thread&.kill
			elapsed = Time.now - @start_time
			elapsed_str = format_time(elapsed)
			if final_message
				puts "\r#{final_message} #{elapsed_str} ✓"
			else
				puts "\r#{@message} #{elapsed_str} ✓"
			end
		end

		private

		def format_time(seconds)
			if seconds < 60
				"#{seconds.round(1)}s"
			else
				minutes = (seconds / 60).to_i
				secs = (seconds % 60).round(1)
				"#{minutes}m #{secs}s"
			end
		end
	end

	namespace :shadow do

		###
		#
		# Entry point
		#
		###

		namespace :philosopher do

			desc "Print help"
			task help: :environment do
				puts ''
				#rake shadow:philosopher:additional       # SPARQLy philosophical investigations (show additional ones)
				#rake shadow:philosopher:count[cond]      # SPARQLy philosophical investigations (of the tallying variety)
				#rake shadow:philosopher:danker[cond]     # SPARQLy philosophical investigations (of the danker variety)
				#rake shadow:philosopher:explore1         # SPARQLy philosophical investigations (length)
				#rake shadow:philosopher:explore2         # SPARQLy philosophical investigations (show stuff)
				#rake shadow:philosopher:flesh[cond]      # SPARQLy philosophical investigations (flesh out entity properties)
				#rake shadow:philosopher:dumbprop         # SPARQLy philosophical investigations (of the dumb prop variety)
				#rake shadow:philosopher:smartprop        # SPARQLy philosophical investigations (of the smart prop variety)
				#rake shadow:philosopher:labels[cond]     # SPARQLy philosophical investigations (flesh out entity labels)
				#rake shadow:philosopher:measure          # SPARQLy philosophical investigations (of the measureful variety)
				#rake shadow:philosopher:mentions[cond]   # SPARQLy philosophical investigations (of the mentioning variety)
				#rake shadow:philosopher:metric           # SPARQLy philosophical investigations (of the metrical variety)
				#rake shadow:philosopher:pagerank[cond]   # SPARQLy philosophical investigations (of the pageranking variety)
				#rake shadow:philosopher:populate[force]  # SPARQLy philosophical investigations (populate database)
				#rake shadow:philosopher:year             # SPARQLy philosophical investigations (of the yearly variety)
				puts 'populate'
				puts 'year'
				puts 'danker'
				puts 'measure'
				puts 'order2'
				puts ''
			end

			desc "SPARQLy P.I. (length)"
			task explore1: :environment do
				require_relative '../wikidata/query_executor'
				str = THESE_PHILOSOPHERS
				puts '# SPARQL for Wikidata philosopher query'
				puts str.gsub("\t",'')
				puts "\n# Executing query with limit for quick exploration..."
				
				# Add LIMIT for quick exploration
				limited_query = str.gsub('LIMIT 10000', 'LIMIT 100')
				res = Wikidata::QueryExecutor.execute_simple(limited_query, 'explore1_limited', {
					task_name: 'shadow:philosopher:explore1'
				})
				puts "response length: #{res.length}"
			end

			desc "SPARQLy philosophical investigations (show stuff)"
			task explore2: :environment do
				require_relative '../wikidata/query_executor'
				puts "About to execute Wikidata query"
				res = Wikidata::QueryExecutor.execute_philosopher_query({
					task_name: 'shadow:philosopher:explore2'
				})
				show_philosophical_stuff(res)
			end

			desc "Populate database with philosophers from Wikidata using SPARQL query (use force=true to actually create records)"
			task :populate, [:force] => :environment do |task, arg|
				begin
					require_relative '../wikidata/query_executor'
					
					# Execute query using the new utility
					res = Wikidata::QueryExecutor.execute_philosopher_query
					
					Shadow.none
					new = 0
					total = res.length
					bar = progress_bar(total, FORCE)
					external = res.each do |val|
						phil   = val.bindings[:entity]
						entity = phil.to_s.split('entity/').last
						id     = entity[1..-1].to_i
						raise 'bad entity' if 0 >= id
						#s = Philosopher.find_or_create_by!(entity_id: id)
						#s.save!
						if not Philosopher.find_by(entity_id: id)
							label = val.bindings[:entityLabel]
							lang = label.language.nil? ? '' : "@#{label.language}"
							s = "https://www.wikidata.org/wiki/Q#{id.to_s.ljust(8)} with label '#{label}#{lang}'"
							if not arg.force.nil? and ("true" == arg.force.downcase or 't' == arg.force.downcase)
								Philosopher.create!(entity_id: id, populate: true)
								log_task_output("Creating! " + s, 'populate_create')
							else
								log_task_output("Would have created: " + s, 'populate_dryrun')
							end
							new += 1
						end
						update_progress(bar)
					end.length
					existing = Philosopher.all.length
					str = "#{external} philosopher wikidata records in total. #{existing} existing ones. #{new} new ones."
					log_task_output(str, 'populate_summary')
				rescue
					barf $!, 'shadow:populate urk'
				end
			end # task populate

			desc "Find philosophers in Wikidata query results not yet in local database"
			task additional: :environment do
				begin
					require_relative '../wikidata/query_executor'
					res = Wikidata::QueryExecutor.execute_philosopher_query({
						task_name: 'shadow:philosopher:additional'
					})
					Shadow.none
					extra = 0
					these = []
					match = []
					res.each do |val|
						phil   = val.bindings[:entity]
						entity = phil.to_s.split('entity/').last
						id     = entity[1..-1].to_i
						raise 'bad entity' if 0 >= id
						these.push(id)
					end
					existing = Philosopher.all
					ids = existing.pluck(:entity_id)
					these.each { |id|
						if ids.include?(id)
							match.push(id)
						else
							extra += 1
							n = Name.first_shadow_by_lang_order(id)
							if n.nil?
								label = ''
								lang = ''
							else
								label = n.label
								lang = "@#{n.lang}"
							end
							# puts "Found extra https://www.wikidata.org/wiki/Q#{e.entity_id.to_s.ljust(8)} with label '#{label}#{lang}'"
						end
					}
					puts "#{res.length} wikidata philosopher records in total. #{match.length} matching ones. => #{extra} extra ones."
					existing.each { |e|
						if match.include?(e.entity_id)
							#
						else
							n = Name.first_shadow_by_lang_order(e.id)
							if n.nil?
								label = ''
								lang = ''
							else
								label = n.label
								lang = "@#{n.lang}"
							end
							# if they're not mentioned anywhere else
							if not e.borchert and not e.internet and not e.cambridge and not e.kemerling and not e.oxford2 and not e.oxford3 and not e.routledge and not e.dbpedia and not e.inphobool and not e.stanford
								# if they have no pages in the wikiverse
								if 0 == e.linkcount 
									if 0 == e.works.count
										puts "Found obsolete https://www.wikidata.org/wiki/Q#{e.entity_id.to_s.ljust(8)} with label '#{label}#{lang}'"
									end
								end
							end
						end
					}
					puts "#{existing.length} existing philosopher records in total. #{match.length} similar ones. => #{existing.length-match.length} obsolete ones."
				rescue
					barf $!, 'shadow:extra urk'
				end
			end # task extra

			def select(cond)
				if cond.nil?
					p = nil
					puts "'ranked'          Philosopher.order(measure: :desc)"
					puts "'philosophers'    Philosopher.all.order(:entity_id)"
					puts "'works'           Work.all.order(:entity_id)"
					puts "'pagerank_n'      Philosopher.order(:entity_id).where(danker: nil)"
					puts "'metric_n'        Philosopher.where(metric: nil)"
					puts "'measure_n'       Philosopher.where(measure: nil)"
					puts "'mention_z'       Philosopher.where(mention: 0)"
					puts "'linkcount_z'     Philosopher.where(linkcount: 0)"
					puts "'linkcount_n'     Philosopher.where(linkcount: nil)"
					puts "'linkcount_n_z'   Philosopher.where(linkcount: [0, nil])"
					puts "'birth_n'         Philosopher.where(birth: nil)"
					puts "'death_n'         Philosopher.where(death: nil)"
					puts "'extra'           Philosopher.where(populate: false)"
					puts "'c_today'         Philosopher.created_today()"
					puts "'u_today'         Philosopher.updated_today()"
					puts "'c_hour'          Philosopher.created_this_hour()"
					puts "'u_hour'          Philosopher.updated_this_hour()"
					puts "/P\\d+/            P::Smart.where(type: P::/P\\d+/)" # wrong indent cuz of the \\
					puts "/D\\d+/            P::Smart.where(type: P::/D\\d+/)" # wrong indent cuz of the \\
					puts "/Q\\d+/            Shadow.find_by(entity_id: cond.to_i)" # wrong indent cuz of the \\
					puts "/\\d+/             Shadow.find(cond.to_i)" # wrong indent cuz of the \\
					puts "[bool_cond]       Philosopher.where(populate: false, :\"bool_cond\" => true)"
				else
					Shadow.none
					case cond
					when 'ranked'
						p = Philosopher.order(measure: :desc)
					when 'philosophers'
						p = Philosopher.all.order(:entity_id)
					when 'works'
						p = Work.all.order(:entity_id)
					when 'pagerank_n'
						p = Philosopher.order(:entity_id).where(danker: nil)
					when 'metric_n'
						p = Philosopher.where(metric: nil)
					when 'measure_n'
						p = Philosopher.where(measure: nil)
					when 'mention_z'
						p = Philosopher.where(mention: 0)
					when 'linkcount_z'
						p = Philosopher.where(linkcount: 0)
					when 'linkcount_n'
						p = Philosopher.where(linkcount: nil)
					when 'linkcount_n_z'
						p = Philosopher.where(linkcount: [0, nil])
					when 'birth_n'
						p = Philosopher.where(birth: nil)
					when 'death_n'
						p = Philosopher.where(death: nil)
					when 'extra'
						p = Philosopher.where(populate: false)
					when 'c_today'
						p = Philosopher.created_today
					when 'u_today'
						p = Philosopher.updated_today
					when 'c_hour'
						p = Philosopher.created_this_hour
					when 'u_hour'
						p = Philosopher.updated_this_hour
					when /P\d+/
						p = P::Smart.where(type: 'P::'+cond).henry.pluck(:object_id).uniq.map{|el|Struct.new(:entity_id).new(el)} # brutal
					when /D\d+/
						p = P::Smart.where(type: 'P::'+cond).pluck(:object_id).uniq.map{|el|Struct.new(:entity_id).new(el)} # brutal
					when /Q\d+/
						p = Shadow.where(entity_id: cond[1..-1].to_i)
					when /\d+/
						p = Shadow.where(id: cond.to_i)
					else
						if not Philosopher.columns_hash[cond].nil? and Philosopher.columns_hash[cond].type == :boolean
							p = Philosopher.where(populate: false, :"#{cond}" => true)
						else
							p = nil
						end
					end
				end
				p
			end

			def birth_death(q, attrs)
				do_date(q, attrs, :birth)
				do_date(q, attrs, :death)
				attrs
			end

			def do_date(q, attrs, date_sym)
				plural = date_sym.to_s.pluralize.to_sym
				approx = (date_sym.to_s+'_approx').to_sym
				explod_birth = [] 
				explod_birth = attrs[plural].split(';') unless attrs[plural].blank?
				if 1 == explod_birth.length
					attrs[date_sym] = attrs[plural].dup # if there's only one i'm pretty sure this is ok
				else
					explod_birth.delete_if{|e| 0 == (e =~ /^t\d+/) }
					if 0 == explod_birth.length
						# um, how to do this?
					elsif 1 == explod_birth.length
						attrs[date_sym] = attrs[plural].dup # if there's only one i'm pretty sure this is ok
					elsif 2 == explod_birth.length
						# check that the years are within X of each other
						begin
							b0 = Date._parse(explod_birth[0])[:year]
							b1 = Date._parse(explod_birth[1])[:year]
							b_diff = (b0 - b1).abs
							if 0 == b_diff
								attrs[date_sym] = explod_birth[0].dup
							elsif b_diff <= 30 # uh, um, eyeballed it
								if b0 > b1
									attrs[date_sym] = explod_birth.dup.reverse.join(';')
								else
									attrs[date_sym] = explod_birth.dup.join(';')
								end
							else
								puts "#{q} #{date_sym} diff too big – #{b_diff}"
							end
						rescue
							puts "#{q} ornery #{date_sym} – #{$!}"
						end
					else
						b_s = []
						explod_birth.each{|e| b_s.push(Date._parse(e)[:year])}
						attrs[date_sym] = b_s.sum / b_s.length
						attrs[approx] = true
					end
				end
				attrs.delete(plural)

				attrs
			end

			desc "Enrich philosopher records with additional Wikidata properties (birth, death, gender, etc.)"
			task :flesh, [:cond] => :environment do |task, arg|
				begin
					phils = select(arg.cond)
					exit if phils.nil?
					count = 0
					disp_count = '%03d'
					total = phils.length
					bar = progress_bar(total, FORCE)
					disp_total = '%0'+(total.to_s.length.to_s)+'d'
					num = 0
					phils.each do |entity|
						attrs = properties("Q#{entity.entity_id}")
						puts attrs
						show=false
						l=' '
						if entity.linkcount != attrs[:linkcount]
							l='L'
							show=true
						end
						b=' '
						unless entity.birth.nil? and attrs[:births].blank?
							begin
								if entity.birth != attrs[:births]
									b='B'
									show=true
								end
							rescue
								b='b'
								show=true
							end
						end
						d=' '
						unless entity.death.nil? and attrs[:deaths].blank?
							begin
								if entity.death != attrs[:deaths]
									d='D'
									show=true
								end
							rescue
								d='d'
								show=true
							end
						end
						num += 1
						q="Q#{entity.entity_id}".ljust(9)
						if show
							count += 1
							puts "#{sprintf(disp_count,count)} of #{sprintf(disp_total,num)}/#{total} #{q} [#{l}#{b}#{d}] #{attrs}"
						end
						attrs = birth_death(q, attrs)
						p attrs
						#
						#entity.update_attributes(attrs)
						update_progress(bar)
					end
					puts "#{count} records changed?"
				rescue
					barf $!, 'shadow:properties urk'
				end
			end # task properties

			def langorder(force, ids=[])
				lo = Name.all.group(:lang).order('count_all desc').count #   column_alias_for("count(*)")                 # => "count_all"
				lo.delete('en_match')
				total = lo.length
				bar = progress_bar(total, force, 'languages')
				lo.each {|v|
					if 0 == ids.length
						Name.where(lang: v[0]).update_all({langorder: v[1]})
					else
						Name.where(shadow_id: ids, lang: v[0]).update_all({langorder: v[1]})
					end
					update_progress(bar)
				}
			end

			def update_labels(e)
				attrs_with_count = labels(e.id, "Q#{e.entity_id}")
				puts "~~~ #{attrs_with_count[:names_attributes].length} labels"
				# {:linkcount=>32,
				#  :names_attributes=> 
				#   [{"id"=>nil, "shadow_id"=>19287, "label"=>"A Vindication of the Rights of Woman", "lang"=>"en", "created_at"=>nil, "updated_at"=>nil, "langorder"=>nil},
				#    {…}]}
				puts attrs_with_count[:names_attributes].select{|attrs| 'en' == attrs['lang']}
				# how to just update?
				Name.where(shadow_id: e.id).delete_all
				e.update_attributes(attrs_with_count)
			end

			# if there's no description they don't show up in bin/rake -T
			# rake shadow:philosopher:labels[cond]
			#
			# Name.uniq.pluck(:lang)
			# Name.uniq.pluck(:shadow_id)
			# Name.all.group(:lang).count
			# Name.all.group(:lang).order('count_all desc').count
			#
			desc "Populate philosopher name labels in multiple languages from Wikidata"
			task :phil_labels, [:cond] => :environment do |task, arg|
				begin
					phils = select(arg.cond)
					exit if phils.nil?
					total = phils.length
					bar = progress_bar(total, FORCE)
					phils.each do |entity|
						update_labels(entity)
						update_progress(bar)
					end
					langorder(FORCE)
				rescue
					barf $!, 'shadow:labels urk'
				end
			end # task labels

			def xlate(e, l)
				#l = Name.distinct(:lang).limit(10).pluck(:lang)
				lbls = l.collect{|v| "?#{v}Label"}.join(" ").gsub('-','_')
				svcs = l.collect{|v|
					"SERVICE wikibase:label {\n\tbd:serviceParam wikibase:language '#{v}' .\n\twd:#{e} rdfs:label ?#{v.gsub('-','_')}Label .\n} hint:Prior hint:runLast false."
				}.join("\n")
				"SELECT #{lbls} WHERE {\n#{svcs}\n}\nGROUP BY #{lbls}"
			end

			def xlate2(e, l)
				#l = Name.distinct(:lang).limit(10).pluck(:lang)
				lbls = l.collect{|v| "?#{v}Label"}.join(" ").gsub('-','_')
				svcs = l.collect{|v| lbl='?'+v.gsub('-','_')+'Label'; "OPTIONAL {wd:#{e} rdfs:label #{lbl} FILTER (lang(#{lbl}) = '#{v}')}."}.join("\n")
				"SELECT #{lbls} WHERE {\n#{svcs}\n}\nGROUP BY #{lbls}"
			end

			def check_date(p, birth, death)
				begin
					new_b = Date._parse(p.birth)[:year]
				rescue
					new_b = nil
				end
				begin
					new_d = Date._parse(p.death)[:year]
				rescue
					new_d = nil
				end
				begin
					if (birth == new_b) and (death == new_d)
						return true
					elsif (birth == new_b) and (death == new_d+1)
						return true
					elsif (birth == new_b) and (death == new_d-1)
						return true
					elsif (birth == new_b+1) and (death == new_d)
						return true
					elsif (birth == new_b-1) and (death == new_d)
						return true
					end
					return false
				rescue
					return false
				end
			end

			def make_append(p)
				begin
					append = " (#{Date._parse(p.birth)[:year]}"
				rescue
					append = " ("
				end
				begin
					append += "/#{Date._parse(p.death)[:year]})"
				rescue
					append += "/)"
				end
			end

			desc "SPARQLy philosophical investigations (of the individual dbpedia variety)"
			task :subject_info, [:cond,:dbp] => :environment do |task, arg|
				require 'knowledge'
				include Knowledge
				p arg.cond
				p arg.dbp
				SUBJECT_TO_DBO = {
					'school'   => DBpedia::DBO_PHILOSOPHICAL_SCHOOL,
					'interest' => DBpedia::DBO_MAIN_INTEREST,
					'subject'  => DBpedia::DCT_SUBJECT
				}
				SUBJECT_TO_KLASS = { # TODO P::Smart.dbpedia_property()
					'school'   => P::D1,
					'interest' => P::D2,
					'subject'  => P::D3
				}
				if arg.dbp.nil? || !SUBJECT_TO_DBO.key?(arg.dbp)
					puts 'Subject must be one of: '+SUBJECT_TO_DBO.keys.join(',')
					exit
				end
				dbo = SUBJECT_TO_DBO[arg.dbp]
				p dbo
				prop_klass = SUBJECT_TO_KLASS[arg.dbp]
				prop_klass.connection
				p prop_klass
				LAST_RUN = 'tmp/.last_run_'+(prop_klass.to_s.sub('::','_'))
				p LAST_RUN
				begin
					puts "reading file: #{LAST_RUN}"
					file_data_lines = File.read(LAST_RUN)
					phils = file_data_lines.each_line.collect{|l| Struct.new(:entity_id).new(l.strip.to_i)}
					puts "unlinking file: #{LAST_RUN}"
					File.unlink(LAST_RUN)
					puts "restarting"
				rescue
					puts "not restarting"
					phils = select(arg.cond)
					exit if phils.nil?
				end
				puts "before ==> #{phils.size}"
				entity_ids = prop_klass.pluck(:entity_id).uniq
				puts "Already processed #{entity_ids.size} records"
				phils = phils.select {|phil| !entity_ids.include?(phil.entity_id )}
				puts "after ==> #{phils.size}"
				puts "creating file: #{LAST_RUN}"
				File.new(LAST_RUN, "w")
				bar = progress_bar(phils.size, FORCE)

				# prop_klass.delete_all

				phils.each do |phil|
					# p phil
					e = phil.entity_id.to_s
					q = 'Q'+e
					# p q # mind your p's and q's
					begin
						subject_info = DBpedia::entity_property_values q
						prop_klass.where(entity_id: phil.entity_id).delete_all
						# pp subject_info
						# Q16895642 => http://dbpedia.org/ontology/philosophicalSchool
						# P737 (influenced by) => http://dbpedia.org/ontology/influencedBy
						# P2348 (time period) => http://dbpedia.org/ontology/era
						# P276 (location) => http://dbpedia.org/ontology/region
						subject_info.each { |solution|
							prop = solution[:p]
							if prop == dbo
								res_label = solution[:o].to_s.split('resource/').last
								object_id = if solution[:w].nil?
									nil
								else
									solution[:w]
								end
								dbp = prop_klass.new
								dbp.entity_id = phil.entity_id
								q = Knowledge::Wikipedia::API::wikibase_item({pageids: object_id})
								dbp.object_id = q[1..-1] unless q.nil?
								dbp.object_label = res_label # have to get wikidata object id from dbpedia res
								dbp.save!
							end
						}
						update_progress(bar)
					rescue
						File.write(LAST_RUN, "#{e}\n", File.size(LAST_RUN), mode: 'a')
						puts $!
					end
				end
			end

			desc "SPARQLy philosophical investigations (of the dbpedia variety)"
			task dbpedia: :environment do
				require 'knowledge'
				include Knowledge
				phil_ranks = DBpedia::pagerank_of_philosophers
				longest = 0
				# many of these map to Gregorian
				# Conversion of Hijri A.H. (Islamic) and A.D. Christian (Gregorian) dates
				# http://www.muslimphilosophy.com/ip/hijri.htm
				amend_date = {
					'Abd al-Husayn Sharaf al-Din al-Musawi' => [1873,1957],
					'Abd-al-Baqi al-Zurqani'  => [1611,1688],
					'Abd-Allah ibn Numayr'   => [nil,814],
					'Abu Bakr al-Sajistani'  => [nil,941],
					'Abu Yusuf'           => [735,798],
					'Aenesidemus'         => [-79,-9],
					'Agnodice'            => [-400,-400],
					'Anthony Weston'      => [1974,nil],
					'Apollonius of Tyana' => [100,200],
					"Atiyya ibn Sa'd"     => [nil,729],
					'Bannanje Govindacharya'  => [1936,nil],
					'Carl Cohen'          => [1931,nil],
					'Cleopatra the Alchemist' => [300,300],
					'David Hume'          => [1711,1776],
					'Duran Çetin'         => [1964,nil],
					'Edward Feser'        => [1968,nil],
					'Elena Oznobkina'     => [1959,2010],
					'François Zourabichvili' => [1965,2006],
					'Gusainji'            => [1516,nil],
					'Hammam ibn Munabbih' => [nil,719],
					'Hamza Makhdoom'      => [1494,1576],
					'Ibn Abd al-Hadi'     => [1305,1343],
					'Ibn Abi Asim'        => [821,900],
					'Ibn Battah'          => [916,997],
					'Imam Muhammad Anwaarullah Farooqui'    => [1849,1918],
					'Ioane Petritsi'      => [1100,1200],
					'Irfan Abidi'         => [1950,1997],
					'Jayanta Bhatta'      => [900,900],
					"Ka'ab al-Ahbar"      => [nil,652],
					'Kanada'              => [-200,-200],
					'Laozi'               => [-600,-500],
					'Leucippus'           => [-500,-500],
					'Mirza Mazhar Jan-e-Janaan' => [1699,1781],
					'Moinuddin Chishti'   => [1142,1236],
					'Muhammad Usman Damani'     => [1828,1897],
					'Muhsin al-Hakim'     => [1889,1970],
					'Paul Thagard'        => [1950,nil],
					'Pāṇini'              => [-600,-400],
					'Philip Lindholm'     => [nil,nil],
					'Pseudo-Dionysius the Areopagite' => [500,600],
					'Roberta Klatzky'     => [1947,nil],
					'Sufyan al-Thawri'    => [716,778],
					'Yusuf ibn Abd al-Rahman al-Mizzi' => [1256,1342],
					'Zenon Pylyshyn'      => [1937,nil]
				}
				phil_ranks.each do |phil_rank|
					s = phil_rank.bindings[:s].to_s.split('resource/').last
					if s.length > longest
						longest = s.length
					end
				end
				longest += 12 # accommodate (b-d)
				nam = 0
				w = Knowledge::Wikidata::Client.new
				Shadow.none
				reach = false
				#many = []
				#count_many = 0
				missing = 0
				batch = []
				total = phil_ranks.length
				bar = progress_bar(total, FORCE)
				phil_ranks.each do |phil_rank|
					update_progress(bar)
					s = phil_rank.bindings[:s].to_s.split('resource/').last
					#if many.include?(s)
					#	count_many += 1
					#else
					#	many.push(s)
					#end
					idx = (s =~ /^(.+)_\(.+\)/)
					if 0 == idx
						s = $1
					end
					s = s.gsub('_',' ')
					#if not reach
					#	if amend_date.first[0] == s
					#		reach = true
					#	else
					#		next
					#	end
					#end
					v = phil_rank.bindings[:v].to_s.to_f
					b = phil_rank.bindings[:b].nil? ? nil : phil_rank.bindings[:b].to_s.to_i
					d = phil_rank.bindings[:d].nil? ? nil : phil_rank.bindings[:d].to_s.to_i
					wiki = phil_rank.bindings[:w].to_s.split('wiki/').last
					ee = wikibase_item({titles: wiki})
					if ee.nil?
						missing += 1
						next
					end

					#if amend_date.key?(s)
					#	b = amend_date[s][0]
					#	d = amend_date[s][1]
					#end

					#if (not b.nil?) and (b == '' or (b >= 0 and b <= 31))
					#	binding.pry
					#end
					#if (not d.nil?) and (d == '' or (d >= 0 and d <= 31))
					#	binding.pry
					#end
					t = " (#{b}–#{d})"
					# check in original population

					#if q_name.key?(s+t)
					if true # :)
						#e = q_name[s+t]
						#if e != ee
						#	binding.pry
						#end
						e = ee
						append = " https://www.wikidata.org/wiki/#{e}"
						begin
							id = e[1..-1].to_i
							p = Philosopher.find_by!(entity_id: id) # is it in the population?
							if not p.dbpedia
								discard = p.update(dbpedia: true, dbpedia_pagerank: v)
							end
						rescue ActiveRecord::RecordNotFound => oops # nope
							res = Wikidata::QueryExecutor.find_philosopher_by_id(e, {
								task_name: 'shadow:danker:update'
							})
							attrs = res.bindings
							same = attrs[:same]
							lc = attrs[:linkcount].first.to_i
							attrs = birth_death(attrs)
							p = Philosopher.new(entity_id: id, birth: attrs[:birth], death: attrs[:death], linkcount: lc, dbpedia: true, dbpedia_pagerank: v)
							#if check_date(p,b,d)
								p.save!
							#elsif amend_date.key?(s)
							#	b = amend_date[s][0]
							#	d = amend_date[s][1]
							#	t1 = " → (#{b}–#{d})"
							#	batch.push("∞ #{s+t+t1} #{other_b}/#{other_d}")
							#else
							#	batch.push(s+t)
							#end
						end
						next # a huge chunk was taken out
					end

				end
				pp batch
				puts "#{phil_ranks.length} unique records"
				puts "updated #{Philosopher.where(dbpedia: true).count}"
				puts "failed to insert #{batch.length}"
				puts "#{missing} missing"
				puts
				puts "dbpedia ones created today: #{Philosopher.created_today.where(dbpedia: true).length} (may not have been this session)"
				# where is the begin?
			end

			#
			# LC_COLLATE=C sort -d db/danker/2019-05-10.all.links.rank > db/danker/2019-05-10.all.links.c.alphanum
			# sed 's/\t/,/g' db/danker/2019-05-10.all.links.c.alphanum > db/danker/2019-05-10.all.links.c.alphanum.csv
			#
			# time taken dropped from 2 hours to 1 minute by sorting and doing a binary search
			# i'm kinda bad-ass at times
			#
			desc "Danker ranks - loads latest danker data with snapshot tracking"
			task :danker, [:cond] => :environment do |task, arg|
				begin
					# Ensure we have the latest danker data
					puts "Checking for latest danker data..."
					system("rake danker:update")
					
					shadows = select(arg.cond)
					exit if shadows.nil?
					total = shadows.length
					bar = progress_bar(total, FORCE)
					
					# Find latest danker directory
					danker_dirs = Dir.glob(Rails.root.join('db', 'danker_*')).sort
					if danker_dirs.empty?
						STDERR.puts "ERROR: No danker data found. Run 'rake danker:update' first."
						exit 1
					end
					
					latest_dir = danker_dirs.last
					danker_version = File.basename(latest_dir)
					
					# Look for CSV file first (optimized for binary search), then compressed format
					csv_files = Dir.glob(File.join(latest_dir, '*.c.alphanum.csv'))
					bz2_files = Dir.glob(File.join(latest_dir, '*.rank.bz2'))
					
					fn = nil
					use_look_command = false
					
					if !csv_files.empty?
						fn = csv_files.first
						use_look_command = true
						puts "Found CSV format (optimized): #{File.basename(fn)}"
					elsif !bz2_files.empty?
						fn = bz2_files.first
						use_look_command = false
						puts "Found compressed format: #{File.basename(fn)}"
						puts "⚠ Note: For better performance, run 'rake danker:process_files' to generate CSV"
					else
						STDERR.puts "ERROR: No danker data file found in #{latest_dir}"
						STDERR.puts "Looking for: *.c.alphanum.csv or *.rank.bz2"
						exit 1
					end
					
					puts "Using danker data: #{danker_version}"
					puts "Data file: #{File.basename(fn)}"
					puts "Lookup method: #{use_look_command ? 'Binary search (look command)' : 'Memory loading'}"
					
					shadows.each do |shade|
						update_progress(bar)
						ent = shade.entity_id
						
						# Get new danker score using optimized lookup
						if use_look_command
							# Use binary search with look command (fast!)
							urk = `look Q#{ent}, #{fn}`
							new_danker_score = urk.empty? ? 0.0 : urk.split(",")[1].to_f
						else
							# Fall back to memory lookup if no CSV available
							danker_scores ||= {}
							if danker_scores.empty?
								puts "Loading compressed data into memory..."
								IO.popen("bzcat #{fn}") do |io|
									io.each_line do |line|
										entity_id, score = line.strip.split("\t")
										if entity_id&.start_with?('Q')
											danker_scores[entity_id[1..-1].to_i] = score.to_f
										end
									end
								end
								puts "Loaded #{danker_scores.size} danker scores"
							end
							new_danker_score = danker_scores[ent] || 0.0
						end
						
						q = "Q#{ent}".ljust(9)
						old_danker_score = shade.danker || 0.0
						puts "#{q} #{old_danker_score} → #{new_danker_score}" if bar.nil?
						
						# Get current values for snapshot
						
						# Only create snapshot if danker score changed
						if old_danker_score != new_danker_score
							# Collect all current input values for self-contained snapshot
							input_values = {
								stanford: shade.stanford || false,
								oxford2: shade.oxford2 || false,
								oxford3: shade.oxford3 || false,
								cambridge: shade.cambridge || false,
								internet: shade.internet || false,
								routledge: shade.routledge || false,
								britannica: shade.britannica || false,
								linkcount: shade.linkcount || 0,
								mention_count: shade.mention || 0,
								old_danker_score: old_danker_score,
								new_danker_score: new_danker_score
							}

							# Get encyclopedia flags for storage
							encyclopedia_flags = {
								stanford: shade.stanford || false,
								oxford2: shade.oxford2 || false,
								oxford3: shade.oxford3 || false,
								cambridge: shade.cambridge || false,
								internet: shade.internet || false,
								routledge: shade.routledge || false,
								britannica: shade.britannica || false
							}
							
							MetricSnapshot.create!(
								philosopher_id: shade.id,
								calculated_at: Time.current,
								measure: shade.measure,
								measure_pos: shade.measure_pos,
								danker_version: danker_version,
								danker_file: File.basename(fn),
								algorithm_version: 'danker_import_v2_self_contained',
								notes: "Danker score updated from #{old_danker_score} to #{new_danker_score}",
								# Store input values in new self-contained fields
								input_values: input_values.to_json,
								danker_score: new_danker_score,
								encyclopedia_flags: encyclopedia_flags.to_json,
								linkcount: shade.linkcount || 0,
								mention_count: shade.mention || 0
							)
							
							# DO NOT update shadows.danker - preserve historical data
							# shade.update(danker: new_danker_score)  # REMOVED FOR SELF-CONTAINED APPROACH
						end
					end
					
					puts "\n✓ Danker import completed using version #{danker_version}"
					puts "✓ Self-contained snapshots created - historical data preserved"
				rescue => e
					STDERR.puts "ERROR: #{e.message}"
					STDERR.puts e.backtrace.first(5)
				end
			end

			# arg.cond
			desc "SPARQLy philosophical investigations (of the pageranking variety)"
			task :pagerank, [:cond] => :environment do |task, arg|
				phils = select(arg.cond)
				exit if phils.nil?
				total = phils.length
				bar = progress_bar(total, FORCE)
				require 'knowledge'
				include Knowledge
				phils.each do |phil|
					update_progress(bar)
					site,title = Wikidata::API::wiki_title("Q#{phil.entity_id}")
					res = DBpedia::pagerank_of_one_resource title
					begin
						urk = res.bindings[:v].first.to_s.to_f
						phil.update(dbpedia_pagerank: urk)
						q = "Q#{phil.entity_id}".ljust(9)
						puts "#{q} #{urk}"
					rescue
						puts "No data for #{title}"
					end
				end
			end

			desc "Count philosophers matching optional SQL-like condition (for testing/validation)"
			task :count, [:cond] => :environment do |task, arg|
				phils = select(arg.cond)
				total = if phils.nil?
					0
				else
					phils.length
				end
				puts "Would process #{total} record(s)"
			end

			# fix these, generally 7th century becomes 700 rather than 600 for instance
			# comment these out when there work is done
			def date_tweak
				p = Philosopher.find_by(entity_id: 9333)
				p.birth = "-604-01-01T00:00:00Z"
				p.death = "-531-01-01T00:00:00Z"
				p.birth_approx = true
				p.death_approx = true
				p.save!
				p = Philosopher.find_by(entity_id: 10261)
				p.birth = "-572-01-01T00:00:00Z"
				p.death = "-497-01-01T00:00:00Z"
				p.birth_approx = true
				p.death_approx = true
				p.save!
				p = Philosopher.find_by(entity_id: 59138)
				p.birth = "0300-01-01T00:00:00Z"
				p.death = "0300-01-01T00:00:00Z"
				p.save!
				p = Philosopher.find_by(entity_id: 76501)
				p.birth = "1882-02-20T00:00:00Z"
				p.save!
				p = Philosopher.find_by(entity_id: 967356)
				p.birth = "1300-01-01T00:00:00Z"
				p.birth_approx = true
				p.save!
				p = Philosopher.find_by(entity_id: 258369)
				p.death = "1072-01-01T00:00:00Z"
				p.save!
				p = Philosopher.find_by(entity_id: 165589)
				p.birth = "-500-01-01T00:00:00Z"
				p.death = "-400-01-01T00:00:00Z"
				p.birth_approx = true
				p.death_approx = true
				p.save!
				p = Philosopher.find_by(entity_id: 188332)
				p.birth = "-500-01-01T00:00:00Z"
				p.birth_approx = true
				p.save!
				p = Philosopher.find_by(entity_id: 320546)
				p.birth = "1200-01-01T00:00:00Z"
				p.birth_approx = true
				p.save!
				p = Philosopher.find_by(entity_id: 335371)
				p.birth = "1238-01-01T00:00:00Z"
				p.death = "1317-01-01T00:00:00Z"
				p.save!
				p = Philosopher.find_by(entity_id: 428694)
				p.birth = "1200-01-01T00:00:00Z"
				p.birth_approx = true
				p.save!
				p = Philosopher.find_by(entity_id: 457990)
				p.birth = "0600-01-01T00:00:00Z"
				p.birth_approx = true
				p.save!
				p = Philosopher.find_by(entity_id: 556865)
				p.birth = "-300-01-01T00:00:00Z"
				p.birth_approx = true
				p.save!
				p = Philosopher.find_by(entity_id: 960345)
				p.birth = "0300-01-01T00:00:00Z"
				p.death = "0400-01-01T00:00:00Z"
				p.birth_approx = true
				p.death_approx = true
				p.save!

				# 20th century :(

				# 10261,    '(c. 572
			end

			desc "Extract and normalize birth/death years from date fields for all philosophers"
			task year: :environment do
				Shadow.none
				phils = Philosopher.all
				bar = progress_bar(phils.size, FORCE)
				date_tweak
				phils.each do |phil|
					birth_year = phil.year(:birth)
					death_year = phil.year(:death)
					phil.update(birth_year: birth_year, death_year: death_year)
					update_progress(bar)
				end
			end

			desc "Show philosophers grouped by philosophical capacity/role (e.g., 'ethicist', 'logician')"
			task :capacities, [:ent] => :environment do |task, arg|
				ents = []
				Shadow.none
				ent = Capacity.find_by(label: arg.ent)
				ents.push(ent.entity_id) unless ent.nil?
				arg.extras.each {|the_ent|
					ent = Capacity.find_by(label: the_ent)
					ents.push(ent.entity_id) unless ent.nil?
				}
				p ents
				phils = Role.where(entity_id: ents).group(:shadow_id).size
				#phils = Philosopher.all
				#bar = progress_bar(phils.size.length, FORCE)
				phils.each do |phil|
					puts phil[1].to_s+': '+Philosopher.find(phil[0]).english #if phil.where(entity_id: 41217).length > 0
					#update_progress(bar)
				end
			end

			def which_slot(y)
				if 2000 == y # means 20th cent.
					return 0
				else
					return 19 - y/100
				end
			end

			desc "Analyze and report gender distribution of philosophers by time period"
			task gender: :environment do
				Shadow.none
				phils = Philosopher.all.order(:birth_year).reverse
				bar = progress_bar(phils.size, FORCE)
				m = []
				f = []
				p = []
				no_data = 0
				
				phils.each do |phil|
					year = if phil.birth_year.nil?
						if phil.death_year.nil?
							nil
						else
							phil.death_year - 50
						end
					else
						phil.birth_year
					end
					if year.nil?
						no_data += 1
					else
						use = if phil.gender == 'Q6581097' # male
							m
						else
							f
						end
						slot = which_slot(year)
						#printf "#{slot} #{year} "
						begin
							use[slot] += 1
						rescue
							use[slot] = 1
						end
						update_progress(bar)
					end
				end
				puts "No data for #{no_data} :("
				max = 29
				i = 0
				while i < max
					n = if f[i].nil?
						f[i] = 0
						0.0
					else
						f[i].to_f
					end
					d = m[i].to_f
					per = n/d*100
					p[i] = sprintf("%02.2f%", per)
					i += 1
				end
				p m[0..max-1]
				p f
				p p
			end

			desc "SPARQLy philosophical investigations (of the dumb property variety)"
			task :dumbprop, [:data] => :environment do |task, arg|
				Shadow.none
				# phils = Philosopher.all
				puts 'broke'
				exit
				phil_set = Philosopher.pluck(:entity_id)
				prop_set = Property.where(property_id: arg.data.to_i).pluck(:original_id).uniq
				redo_set = phil_set - prop_set
				bar = progress_bar(redo_set.size, FORCE)
				redo_set.each do |entity_id|
					# binding.pry
					datum(entity_id, arg.data) {|line|
						# p line
						prop  = Property.new
						prop.property_id = arg.data.to_i
						# can never be nil !
						prop.entity_id = line.bindings[:q].to_s.split('entity/').last[1..-1].to_i
						prop.entity_label = line.bindings[:qLabel].to_s
						prop.original_id = entity_id
						# guaranteed to no to be nil
						prop.data_id = line.bindings[:data].to_s.split('entity/').last[1..-1].to_i
						prop.data_label = line.bindings[:dataLabel].to_s
						# could be nil :)
						if line.bindings[:instance].nil?
							prop.instance_id = nil
							prop.instance_label = nil
						else
							prop.instance_id = line.bindings[:instance].to_s.split('entity/').last[1..-1].to_i
							prop.instance_label = line.bindings[:instanceLabel].to_s
						end
						are_we_here = Property.where(property_id: prop.property_id, entity_id: prop.entity_id, data_id: prop.data_id).first
						pp are_we_here
						puts "original id: #{entity_id}"
						are_we_here.delete unless are_we_here.nil?
						prop.save!
					}
					update_progress(bar)
				end
			end

			#
			# leave cond empty to print cond
			# bin/rake shadow:philosopher:smartprop[,19]
			#
			desc "SPARQLy philosophical investigations (of the smart wikidata property variety)"
			task :smartprop, [:cond,:prop_id,:force] => :environment do |task, arg|
				phils = select(arg.cond)
				puts "before ==> #{phils.size}"
				prop_klass  = P::Smart.property(arg.prop_id)
				p prop_klass
				if arg.force.nil? or 'force' != arg.force
					if "31" == arg.prop_id
						entity_ids = prop_klass.pluck(:entity_id).uniq
					else
						entity_ids = prop_klass.pluck(:object_id).uniq
					end
					puts "Already processed #{entity_ids.size} records"
					phils = phils.select {|phil| !entity_ids.include?(phil.entity_id )}
				end
				puts "after ==> #{phils.size}"
				puts 'nothing to do!' && exit if phils.nil? or phils.size.nil?
				bar = progress_bar(phils.size, FORCE)
				phils.each do |phil|
					entity_id = phil.entity_id
					lines = object(entity_id, arg.prop_id) {|line|
						# p line
						prop = prop_klass.new
						prop.redirect_id      = entity_id # should be called redirect_from_id
						prop.entity_id        = line.bindings[:q].to_s.split('entity/').last[1..-1].to_i
						prop.object_id        = line.bindings[:datum].to_s.split('entity/').last[1..-1].to_i
						prop.object_label     = line.bindings[:datumLabel].to_s
						are_we_here = prop_klass.find_by(redirect_id: prop.redirect_id, object_id: prop.object_id)
						are_we_here.delete unless are_we_here.nil?
						prop.save!
					}
					Rails.logger.info "Smart Property: #{arg.cond} (#{entity_id} P#{arg.prop_id} => #{lines} line#{'s' unless 1==lines}"
					update_progress(bar)
				end
			end

			# bin/rake shadow:philosopher:smartprop[philosophers,19]
			# bin/rake shadow:philosopher:smartprop[P19,31]
			# bin/rake shadow:philosopher:smartprop[philosophers,20]
			# bin/rake shadow:philosopher:smartprop[P20,31]
			# bin/rake shadow:philosopher:locale_infer
			# bin/rake shadow:philosopher:locale_build

			desc "SPARQLy philosophical investigations (of the locale variety)"
			task locale_infer: :environment do
				each_locale(19)
				each_locale(20)
			end

			desc "SPARQLy philosophical investigations (of the locale variety)"
			task locale_build: :environment do
				P::J27.delete_all	
				entity_country_list = P::P27.all
				bar = progress_bar(entity_country_list.size, FORCE)
				entity_country_list.each{ |entity_country|
					vc = P::J27.new
					vc.entity_id = entity_country.entity_id
					vc.object_id = entity_country.object_id
					vc.object_label = entity_country.object_label
					vc.save!
					update_progress(bar)
				}
				place_country_list = P::J1.all
				bar = progress_bar(place_country_list.size, FORCE)
				place_country_list.each{ |place_country|
					# entity_place_list = P::P19.pluck(:entity_id, :object_id)
					# entity_place_list.each{ |entity_id, place_id|
					entity_place_list = P::P19.where(object_id: place_country.entity_id)
					entity_place_list.each{ |entity_place|
						vc = P::J27.new
						vc.entity_id = entity_place.entity_id
						vc.object_id = place_country.object_id
						vc.object_label = place_country.object_label
						vc.save!
					}
					entity_place_list = P::P20.where(object_id: place_country.entity_id)
					entity_place_list.each{ |entity_place|
						vc = P::J27.new
						vc.entity_id = entity_place.entity_id
						vc.object_id = place_country.object_id
						vc.object_label = place_country.object_label
						vc.save!
					}
					update_progress(bar)
				}
			end

			# ok places
			PLACE_WHITELIST={
				727 => "Amsterdam",   # {:q=>#<RDF::URI:0x263a84c URI:http://www.wikidata.org/entity/Q727>,   :qLabel=>#<RDF::Literal:0x263a6f8("Amsterdam"@en)>}
				3616 => "Tehran",     # {:q=>#<RDF::URI:0x2538368 URI:http://www.wikidata.org/entity/Q3616>,  :qLabel=>#<RDF::Literal:0x2538250("Tehran"@en)>}
				1748 => "Copenhagen", # {:q=>#<RDF::URI:0x250010c URI:http://www.wikidata.org/entity/Q1748>,  :qLabel=>#<RDF::Literal:0x24fffa4("Copenhagen"@en)>}
				36600 => "The Hague", # {:q=>#<RDF::URI:0x23b5158 URI:http://www.wikidata.org/entity/Q36600>, :qLabel=>#<RDF::Literal:0x23b5004("The Hague"@en)>}
			}

			# not a place or irreducible to their connecting places
			PLACE_BLACKLIST={
				97     => "Atlantic Ocean",      # {:q=>#<RDF::URI:0x2dc6bc4 URI:http://www.wikidata.org/entity/Q97>,     :qLabel=>#<RDF::Literal:0x2dc691c("Atlantic Ocean"@en)>}
				4918   => "Mediterranean Sea",   # {:q=>#<RDF::URI:0x2f14e68 URI:http://www.wikidata.org/entity/Q4918>,   :qLabel=>#<RDF::Literal:0x2f14d3c("Mediterranean Sea"@en)>}
				8646   => "Hong Kong",           # {:q=>#<RDF::URI:0x24fee24 URI:http://www.wikidata.org/entity/Q8646>,   :qLabel=>#<RDF::Literal:0x24fed0c("Hong Kong"@en)>}
				37495  => "Ionian Sea",          # {:q=>#<RDF::URI:0x2704fc0 URI:http://www.wikidata.org/entity/Q37495>,  :qLabel=>#<RDF::Literal:0x2704e44("Ionian Sea"@en)>}
				43100  => "Kashmir",             # {:q=>#<RDF::URI:0x2291074 URI:http://www.wikidata.org/entity/Q43100>,  :qLabel=>#<RDF::Literal:0x228f378("Kashmir"@en)>}
				38060  => "Gaul",                # {:q=>#<RDF::URI:0x314f91c URI:http://www.wikidata.org/entity/Q38060>,  :qLabel=>#<RDF::Literal:0x314f7dc("Gaul"@en)>}
				223604 => "Greco-Italian War",   # {:q=>#<RDF::URI:0x23a3840 URI:http://www.wikidata.org/entity/Q223604>, :qLabel=>#<RDF::Literal:0x23a3700("Greco-Italian War"@en)>}
				26     => "Northern Ireland",    # {:q=>#<RDF::URI:0x2e36604 URI:http://www.wikidata.org/entity/Q26>,     :qLabel=>#<RDF::Literal:0x2e3644c("Northern Ireland"@en)>}
				60140  => "Indian Subcontinent", # {:q=>#<RDF::URI:0x250e6e4 URI:http://www.wikidata.org/entity/Q60140>, :qLabel=>#<RDF::Literal:0x250e16c("Indian subcontinent"@en)>}
			}

			def insert_locale(rec, place_id)
				country_id    = rec.bindings[:connector].to_s.split('entity/').last[1..-1].to_i # hmm, must be a neat-o way of doing this
				country_label = rec.bindings[:connectorLabel].to_s
				inferred = P::J1.new
				inferred.entity_id = place_id
				inferred.object_id = country_id
				inferred.object_label = country_label
				# p inferred
				inferred.save!
			end

			def each_locale(prop_id)
				prop_klass = P::Smart.property(prop_id)
				place_list = prop_klass.group(:object_id).count(:object_id).sort_by {|_key, value| value}.reverse
				# p place_list
				puts "#{place_list.size} places in P:P#{prop_id} (before check)"
				entity_ids = P::J1.pluck(:entity_id).uniq
				place_list.delete_if do |place_id, count|
					entity_ids.include?(place_id)
				end
				puts "#{place_list.size} places in P:P#{prop_id} (after check)"
				bar = progress_bar(place_list.size, FORCE)
				place_list.each do |place_id, count|
					bingo = P::P31.where(entity_id: place_id, object_id: [6256, 3624078, 3024240])
					if bingo.empty?
						substitution_hash = {interpolated_entity: 'Q'+place_id.to_s}
						res = interpolated_entity(ASSOC_COUNTRY_, substitution_hash)
						len = res.length
						update_progress(bar) and next if len.zero?
						# https://www.w3.org/TR/rdf-sparql-query/#modDistinct
						# just_one = res.uniq # god i hope this works as intended, TODO double check!
						if 1 == len
							rec = res.first
							insert_locale(rec, place_id)
						else
							if PLACE_WHITELIST.keys.include?(place_id)
								res.each{ |rec|
									insert_locale(rec, place_id)
								}
							else
								puts "inconclusive place: #{place_id} #{res}" unless PLACE_BLACKLIST.keys.include?(place_id)
							end
						end
					end
					update_progress(bar)
				end
			end

			desc "SPARQLy philosophical investigations (of the ordering variety)"
			task order: :environment do # OBSOLETE
				Shadow.none
				phils = Philosopher.order('metric desc').group(:metric)
				count_phils = phils.count
				length_phils = count_phils.length
				bar = progress_bar(length_phils, FORCE)
				count_phils.each_with_index do |metric, idx|
					Philosopher.where(metric: metric[0]).update_all(metric_pos: idx+1)
					update_progress(bar)
				end
			end

			desc "SPARQLy philosophical investigations (of the order2ing variety)"
			task new_order: :environment do
				Shadow.none
				phils = Philosopher.order('measure desc').group(:measure)
				count_phils = phils.count
				length_phils = count_phils.length
				bar = progress_bar(length_phils, FORCE, 'groups of records')
				count_phils.each_with_index do |measure, idx|
					Philosopher.where(measure: measure[0]).update_all(measure_pos: idx+1)
					update_progress(bar)
				end
			end

			desc "SPARQLy philosophical investigations (of the dbpedia measureful variety)"
			task old_metric: :environment do # OBSOLETE
				Shadow.none
				# less crude
				#Philosopher.update_all('metric = philosophy + philosopher') # use metric as a place_holder, should create new mention_attr
				Philosopher.all
				max_mention = (Philosopher.order('mention desc').first.mention)*1.0
				min_mention = 1
				max_rank = Philosopher.order('dbpedia_pagerank desc').first.dbpedia_pagerank
				min_rank = Philosopher.where.not(dbpedia_pagerank: nil).order('dbpedia_pagerank asc').first.dbpedia_pagerank
				
				# Oxford Dictionary of Philosophy                    Q7755796  3.82001
				# Philosophical Library Dictionary of Philosophy     Q3700851  2.46188
				# Routledge Encyclopedia of Philosophy               Q249821   8.81918
				# Stanford Encyclopedia of Philosophy                Q824553   45.4263
				# Cambridge Dictionary of Philosophy                 Q1761588  3.06268
				# Thomson Gale Encyclopedia of Philosophy            Q1340157  4.65352
				# Internet Encyclopedia of Philosophy                Q259513   26.2852
				# DBpedia – Philosophical Figures                    Q465      3.22946
				# Wikidata – Philosophical Figures                   Q2013     3.53577
				# Philosophy Pages Philosophical Dictionary          Q
				
 				# What about Britannica?				
				
				Philosopher.order(:entity_id).each do |phil|
					runes     = phil.runes     ? 0.0  : 0.0 # because biased
					borchert  = phil.borchert  ? 0.2  : 0.0 # M 
					cambridge = phil.cambridge ? 0.2  : 0.0
					kemerling = phil.kemerling ? 0.1  : 0.0 # because sole affair
					populate  = phil.populate  ? 0.05 : 0.0 # wikidata
					oxford    = phil.oxford    ? 0.2  : 0.0
					routledge = phil.routledge ? 0.2  : 0.0
					dbpedia   = phil.dbpedia   ? 0.05 : 0.0 # don't trust
					stanford  = phil.stanford  ? 0.2  : 0.0

					if phil.mention.nil?
						mention = min_mention
					else
						mention = phil.mention
					end
					if phil.dbpedia_pagerank.nil?
						rank = min_rank
					else
						rank = phil.dbpedia_pagerank
					end
					tmp = ((mention/max_mention * rank/max_rank) * (dbpedia+ populate+ routledge+ oxford+ kemerling+ runes+ stanford+ cambridge) * 1000000)
					phil.update(metric: tmp)
					q = "Q#{phil.entity_id}".ljust(9)
					puts "#{q} #{tmp}"
				end
			end

			desc "Calculate canonicity metrics for all philosophers using configurable weights and create audit snapshots"
			task metric: :environment do
				Shadow.none
				total = Philosopher.all.size
				bar = progress_bar(total, FORCE)
				
				# Determine danker version info
				danker_latest_dir = Rails.root.join('db', 'danker', 'latest')
				danker_info = if danker_latest_dir.exist?
					{
						version: danker_latest_dir.readlink.to_s,
						file: Dir.glob(danker_latest_dir.join('*.csv')).first&.then { |f| File.basename(f) }
					}
				else
					{ version: 'unknown', file: 'unknown' }
				end
				
				algorithm_version = '2.0'
				calculation_time = Time.current
				
				puts "Starting canonicity metric calculation:"
				puts "  Algorithm version: #{algorithm_version}"
				puts "  Danker version: #{danker_info[:version]}"
				puts "  Danker file: #{danker_info[:file]}"
				puts "  Calculation time: #{calculation_time}"
				puts ""

				Philosopher.order(:entity_id).each do |phil|
					update_progress(bar)
					
					# Calculate using the model method which handles snapshots
					begin
						measure = phil.calculate_canonicity_measure(
							algorithm_version: algorithm_version,
							danker_info: danker_info
						)
						
						q = "Q#{phil.entity_id}".ljust(9)
						puts "#{q} #{measure}" if bar.nil?
					rescue => e
						STDERR.puts "Error calculating measure for philosopher #{phil.id}: #{e.message}"
					end
				end
				
				puts "\n✓ Canonicity metric calculation completed"
				puts "✓ Created #{total} snapshots for algorithm v#{algorithm_version}"
			end

			def unpack_one(res)
			end

			def apply_language_filters
				require 'knowledge'
				include Knowledge
				w = Knowledge::Wikidata::Client.new
				# lo = Name.all.group(:lang).order('count_all desc').count
				# lo.each {|v| Name.where({lang: v[0]}).update_all({langorder: v[1]})}
				lc = Name.all.group(:lang).order('count_all desc').count
				lc.delete('en_match')
				language_keys = lc.keys
				base = 50 # CHUNK, languages processed as a time from the most frequent to the least frequent
				idx = 0
				#l = Name.all.group(:lang).order('count_all desc').count.keys.first(39)
				until base*idx > language_keys.length # chunk by chunk
					l = language_keys[(base*idx)..((base*(idx+1))-1)]
					#p l
					q = xlate2('Q5891', l) # philosophy
					res1 = Wikidata::QueryExecutor.execute_simple(q, 'xlate_philosophy', {
						task_name: 'shadow:label:xlate'
					})
					#p res1
					q = xlate2('Q4964182', l) # philosopher
					res2 = Wikidata::QueryExecutor.execute_simple(q, 'xlate_philosopher', {
						task_name: 'shadow:label:xlate'
					})
					#p res2
					q = xlate2('Q4964182', l) # philosophical #(
					res3 = Wikidata::QueryExecutor.execute_simple(q, 'xlate_philosophical', {
						task_name: 'shadow:label:xlate'
					})
					#p res3
					idx += 1

					match1 = false
					philosophy = l.collect { |val|
						lbl = :"#{val.gsub('-','_')}Label"
						if not res1.bindings[lbl].nil?
							str = res1.bindings[lbl].first.to_s
							if not str.start_with?('Q')
								match1 = true
								"CONTAINS(lcase(str(?desc)),\"#{str.downcase}\")"
							else
								false
							end
						else
							false
						end
					}.join(" || ")

					match2 = false
					philosopher = l.collect { |val|
						lbl = :"#{val.gsub('-','_')}Label"
						if not res2.bindings[lbl].nil?
							str = res2.bindings[lbl].first.to_s
							if not str.start_with?('Q')
								match2 = true
								"CONTAINS(lcase(str(?desc)),\"#{str.downcase}\")"
							else
								false
							end
						else
							false
						end
					}.join(" || ")

					match3 = false
					philosophical = l.collect { |val|
						lbl = :"#{val.gsub('-','_')}Label"
						if not res3.bindings[lbl].nil?
							str = res3.bindings[lbl].first.to_s
							if not str.start_with?('Q')
								match3 = true
								"CONTAINS(lcase(str(?desc)),\"#{str.downcase}\")"
							else
								false
							end
						else
							false
						end
					}.join(" || ")

					yield({:match => match1, :xlate => philosophy}, {:match => match2, :xlate => philosopher}, {:match => match3, :xlate => philosophical})
				end
			end

			desc ""
			task explore3: :environment do
				filters {|a,b,c|
					puts "philosophy = #{a}"
					puts "philosopher = #{b}"
					puts "philosophical = #{c}"
				}
			end

			def mention_one(entity_id, filters)
				require 'knowledge'
				include Knowledge
				w = Knowledge::Wikidata::Client.new
				case entity_id
				when String
					if entity_id.start_with?('Q')
						entity = entity_id
					else
						raise "bad entity id string #{entity_id}"
					end
				when Integer
					entity = "Q#{entity_id}"
				else
					raise "bad entity id class #{entity_id.inspect}"
				end
				acc = []
				filters.each_with_index { |filter, idx|
					acc[idx] = 0
					#l.each do |val|
					if filter[:match]
						q = HITS2 % {interpolated_entity: entity, interpolated_filter: filter[:xlate]}
						#puts q
						hits = Wikidata::QueryExecutor.execute_simple(q, 'hits_filter', {
							task_name: 'shadow:philosophy:hits'
						})
						acc[idx] += hits.bindings[:hits].first.to_i
					end
					#end
				}
				acc
			end

			# net connection keeps killing this, thus the restart-handling code
			desc "Count mentions of philosophers in philosophical texts and update philosophy/philosopher scores"
			task :mentions, [:cond] => :environment do |task, arg|
				phils = select(arg.cond)
				phils = phils.order(linkcount: :desc)
				exit if phils.nil?
				count_round = -1
				begin
					round, item = File.read('tmp/.phil_mention').split(':').map{|part| part.to_i}
				rescue
					round = 0
					item = 0
					phils.update_all(philosophy: 0, philosopher: 0)
				end
				puts "#{phils.length} records"
				pad = '%0'+phils.length.to_s.length.to_s+'d'
				filters { |filter1, filter2, filter3|
					count_round += 1
					puts "(xxxx of #{phils.length}) Q________ LC  –  round #{count_round}"
					next if count_round < round
					phils.each_with_index do |phil, count_item|
						next if count_item < item
						acc = mention_one(phil.entity_id, [filter1,filter2])
						if acc.sum > 0
							entity = "Q#{phil.entity_id}"
							puts "(#{sprintf(pad,count_item)} of #{phils.length}) #{entity.ljust(9)} #{phil.linkcount.to_s.ljust(3)} (philosophy #{acc[0]} + philosopher #{acc[1]}) = #{acc.sum}"
							attrs = {philosophy: acc[0]+phil.philosophy.to_i, philosopher: acc[1]+phil.philosopher.to_i}
							phil.update_attributes(attrs)
							File.write('tmp/.phil_mention', count_round.to_s+':'+(count_item+1).to_s) # restart at the same round, at the next item
						end
					end
					item = 0
				}
				total = phils.update_all('mention = (philosophy + philosopher)')
				File.unlink('tmp/.phil_mention')
			end

		end # namespace philosopher


	end # namespace shadow

rescue
	barf $!, 'shadow urk: $! has wot you want'
	# binding.pry
end
