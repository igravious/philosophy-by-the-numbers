# frozen_string_literal: true

require_relative '../utilities'
require_relative '../../wikidata/client_helpers'
require_relative '../../wikidata/sparql_queries'
require_relative '../../knowledge'

begin
  include TaskUtilities
  include Wikidata::ClientHelpers
  include Wikidata::SparqlQueries

  FORCE = true

  namespace :shadow do
    namespace :work do

      desc "SPARQLy textual investigations       (show 'em)"
      task :show, [:cond,:count] => :environment do |task, arg|
        begin
          require 'knowledge'
          include Knowledge
          w = Knowledge::Wikidata::Client.new
          case arg.cond
            #
          when "works1"
            q = THESE_WORKS_BY_PHILOSOPHERS.gsub("\t",'')
            res = Wikidata::QueryExecutor.execute(q, 'works_by_philosophers', {
              task_name: 'shadow:work:query'
            })
          when "works2"
            q = THESE_PHILOSOPHICAL_WORKS.gsub("\t",'')
            res = Wikidata::QueryExecutor.execute(q, 'philosophical_works', {
              task_name: 'shadow:work:query'
            })
          end
          if arg.count
            p arg
            puts "count: #{arg.count.inspect}"
            puts "count: #{arg.count.class}"
            puts "foo: #{arg.foo.inspect}"
            puts "Got #{res.size} of 'em"
          else
            show_work_stuff(res)
          end
        rescue
          barf $!, 'work:show urk'
        end
      end

      desc "SPARQLy textual investigations       (connect Works and Texts)"
      task connect: :environment do
        Shadow.none
        phils = Philosopher.order(measure: :desc)
        en_phils = phils.select('shadows.*, names.lang, names.label').joins(:names).where('names.lang =?', 'en')
        en_phils.each {|phil|
          works = Work.where(id: Expression.where(creator_id: phil.id).pluck(:work_id)).order('linkcount desc')
          en_works = works.select('shadows.*, names.lang, names.label').joins(:names).where('names.lang =?', 'en')
          found = 0
          en_works.each do|work|
            label = work.name_hack.nil? ? work.label : work.name_hack # very hacky
            the_text = ::Text.where("name_in_english LIKE '"+label.gsub("'", "''")+"'").first
            if the_text.nil?
            else
              puts "'#{the_text.name_in_english}' #{the_text.fyle_id}" unless the_text.nil?
              found += 1
            end
          end
          puts "===" if found > 0
          texts = ::Text.where(id: Writing.where(author_id: Author.where(english_name: phil.label)).pluck(:text_id))
          texts.each do|text|
            puts "'#{text.name_in_english}' #{text.fyle_id}"
          end
          if found > 0 or texts.count > 0
            puts "==> Q#{phil.entity_id} (#{found}/#{texts.count})"
          end
        }
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
      def deez_wurks(q)
        Shadow.none
        require_relative '../../wikidata/query_executor'
        puts q
        res = Wikidata::QueryExecutor.execute_simple(q, 'deez_wurks', {
          task_name: 'shadow:work:deez_wurks'
        })
        #bar = progress_bar(res.length, FORCE)
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
        rescue
          barf $!, 'work:labels urk'
          binding.pry
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
            rescue
              if entity == name
                puts "FIXME: Work w/ entity id #{entity_id} is not in the db, prolly no author."
              else
                puts "FIXME: Work "#{name}" w/ entity id #{entity_id} is not in the db, prolly no author."
              end
            end
            # update_progress(bar)
          }
        rescue
          barf $!, 'work:snarf urk'
          binding.pry
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
        rescue
          barf $!, 'work:snarf urk'
          binding.pry
        end
      end

      desc "describe works"
      task describe: :environment do
        predicates = {}
        one_by_one(:describe, "DESCRIBE wd:Q%{interpolated_entity}") {|solution_set|
          tmp = {}
          solution_set.each do|solution|
            p = solution.predicate.to_s
            tmp[p] = true
          end
          tmp.keys.each do|p|
            begin
              predicates[p] = predicates[p]+1
            rescue
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
        rescue
          barf $!, 'work:signal urk'
          binding.pry
        end
      end

      desc "SPARQLy textual investigations (of the order2ing variety)"
      task order2: :environment do
        Shadow.none
        works = Work.order('measure desc').group(:measure)
        work_groupings = works.count
        num_work_blocks = work_groupings.length
        bar = progress_bar(num_work_blocks, FORCE, 'groups of records')
        work_groupings.each_with_index do |measure, idx|
          Work.where(measure: measure[0]).update_all(measure_pos: idx+1)
          update_progress(bar)
        end
      end

      desc "SPARQLy textual investigations (of the measureful variety)"
      task measure: :environment do
        Shadow.none
        File.open('works.json'){|f|
          json_works = f.read
          works = JSON.parse(json_works)
          total = works.length
          bar = progress_bar(total, FORCE)
          works.each do |work|
            w = Work.find_by(entity_id: work[0])
            w.cambridge = ('y' == work[2])
            w.borchert = ('y' == work[3])
            w.routledge = ('y' == work[4])
            w.save!
            update_progress(bar)
          end
        }

        total = Work.all.size
        bar = progress_bar(total, FORCE)

        max_mention = (Work.order('mention desc').first.mention)*1.0
        min_mention = 0.5 # if no mention, reduce to zero!
        unranked = Work.where(danker: nil)
        ranked = Work.where.not(danker: 0.0) # o.o
        max_rank = Work.order('danker desc').first.danker # desc (first)
        min_rank = (ranked.order('danker asc').first.danker)/2.0  # asc (first) / 2.0 o.o

        Work.order(:entity_id).each do |work|
          all_bonus = 0.1
          borchert  = work.borchert  ? 0.25 : (all_bonus=0.0) # M 
          cambridge = work.cambridge ? 0.2  : (all_bonus=0.0) # C
          routledge = work.routledge ? 0.25 : (all_bonus=0.0) # R
          philpapers= (work.philrecord or work.philtopic) ? 0.2 : 0.0

          genre = work.genre ? 1.0 : 0.5
          sourcey = borchert+ cambridge+ routledge+ philpapers+ all_bonus
          if 0.0 == sourcey
            sourcey = 0.1 # don't be zero
          end
          exists = 0.0
          phils = Philosopher.where(id: Expression.where(work_id: work.id).pluck(:creator_id))
          if phils.length > 0
            exists = -sourcey if 0.0 == phils.collect{|phil| phil.measure }.sum # counterbalance
          else
            STDERR.puts "Q#{work.entity_id} has no author!"
          end

          if work.mention.nil? or work.mention == 0
            mention = min_mention
          else
            mention = work.mention
          end
          if work.danker.nil?
            rank = min_rank
          else
            rank = work.danker
          end
          # FOUR signals: description * connectedness * authority * size
          tmp = (mention/max_mention) * (rank/max_rank) * (genre) * (sourcey+ exists) * 1000000
          work.update(measure: tmp)
          q = "Q#{work.entity_id}".ljust(9); update_progress(bar, "#{q} #{tmp}")
        end
        null_point = Work.where(measure: 0.0).size
        puts "Null point is #{null_point}, usable works is #{total-null_point}"
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

      desc "populate Work (works table) using philosopher Viaf data"
      task :viaf, [:cond] => :environment do |task, arg|
        Shadow.none
        case arg.cond
        when /^\d+/ # either singly
          phils = [Philosopher.find_by(viaf: arg.cond)]
        else
          phils = Philosopher.all.order(measure: :desc)
        end

        require 'knowledge'
        include Knowledge
        w = Knowledge::Wikidata::Client.new
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
          plucked_qs = phil.works.pluck(:entity_id)
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

      # Helper methods for work tasks
      def one_by_one(task, query_str, in_order={})
        begin
          Shadow.none
          works = Work.order(in_order)
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
        works = doc.xpath('//ns1:work')
        puts "#{works.length} work(s)"
        personal = doc.xpath('//ns1:viafID').first.content
        works.each {|w|
          full_id = w["id"]
          node_set = w.xpath('ns1:title')
          title = node_set.first.content
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
                  expressions = node.xpath('//ns1:expression')
                  try_once = []
                  neither = true
                  expressions.each {|expr|
                    lang = ''
                    begin
                      lang = expr.xpath('ns1:lang').first.content
                    rescue
                      puts "0 #{$!}" 
                    end
                    if "English" == lang
                      begin
                        el = expr.xpath('ns1:title').first
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

rescue => e
  barf e, 'shadow work tasks'
  binding.pry
end