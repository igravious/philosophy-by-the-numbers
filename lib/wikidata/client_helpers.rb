# frozen_string_literal: true

require_relative 'sparql_queries'

module Wikidata
  module ClientHelpers
    
    # SPARQL Query Logging Helper
    def self.log_sparql_query(query, method_name, context = {})
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
      
      # Log file output if SPARQL_LOG is enabled
      if ENV['SPARQL_LOG'] == 'true'
        log_dir = Rails.root.join('log')
        log_file = log_dir.join('sparql_queries.log')
        
        File.open(log_file, 'a') do |f|
          f.puts "\n[#{timestamp}] Method: #{method_name}"
          f.puts "Context: #{context.inspect}" unless context.empty?
          f.puts "Query:"
          f.puts query
          f.puts "-" * 80
        end
      end
    rescue => e
      # Don't let logging errors break the main functionality
      puts "Warning: SPARQL logging failed: #{e.message}" if ENV['SPARQL_DEBUG'] == 'true'
    end
    
    # Instance method version for backward compatibility
    def log_sparql_query(query, method_name, context = {})
      self.class.log_sparql_query(query, method_name, context)
    end
    
    include Wikidata::SparqlQueries

    ###
    #
    # Helper Functions
    #
    ###

    def show_work_stuff(res)
      res.each_with_index do |val, idx|
        phil       = val.bindings[:item]
        work       = val.bindings[:work]
        name       = val.bindings[:workLabel].to_s
        what       = val.bindings[:whatLabel].to_s
        count      = val.bindings[:linkcount].to_i
        p_entity   = phil.to_s.split('entity/').last
        w_entity   = work.to_s.split('entity/').last
        #site,title= Wikidata::API::wiki_title(entity)
        #rating    = mention_one(entity)
        index      = sprintf(" %05d ", idx)
        #mentions  = sprintf("|%10s|", "#"*(rating))
        site_links = sprintf("[%03d]", count)
        # {"entities"=>{"Q3175911"=>{"type"=>"item", "id"=>"Q3175911", "sitelinks"=>{}}}, "success"=>1}
        #if name == title
        #	puts "#{index} #{site_links} #{entity.ljust(9)} #{mentions} #{site.rjust(10)}: #{title}"
        #else
          puts "#{index} #{site_links} #{w_entity.ljust(9)} by #{p_entity.ljust(9)} "#{name}" #{what}"
        #end
      end
    end

    def show_philosophical_stuff(res)
      Shadow.none
      max_mention = ((Philosopher.order('mention desc').first.mention)*1.0)+10.0 # head room
      f1 = []
      f2 = []
      f3 = []
      filters { |filter1, filter2, filter3|
        f1.push(filter1)
        f2.push(filter2)
        f3.push(filter3)
      }
      res.each_with_index do |val, idx|
        phil       = val.bindings[:entity]
        name       = val.bindings[:entityLabel].to_s
        count      = val.bindings[:linkcount].to_i
        entity     = phil.to_s.split('entity/').last
        site,title = Wikidata::API::wiki_title(entity)
        mentions   = 0
        start = Time.now
        f1.length.times {|i|
          mentions += mention_one(entity, [f1[i], f2[i]]).sum
        }
        finish = Time.now
        puts "Filtering took #{finish-start} seconds"
        index      = sprintf(" %05d ", idx)
        rating     = sprintf("|%10s|", "#"*(mentions/max_mention*10))
        site_links = sprintf("[%03d]", count)
        # {"entities"=>{"Q3175911"=>{"type"=>"item", "id"=>"Q3175911", "sitelinks"=>{}}}, "success"=>1}
        if name == title
          puts "#{index} #{site_links} #{entity.ljust(9)} #{rating} #{site.rjust(10)}: #{title}"
        else
          puts "#{index} #{site_links} #{entity.ljust(9)} #{rating} #{site.rjust(10)}: #{title} (#{name})"
        end
      end
    end

    # TODO put exception handling here?
    def interpolated_entity(sparql_query, substitution_hash)
      require 'knowledge'
      include Knowledge
      w = Knowledge::Wikidata::Client.new
      q = sparql_query % substitution_hash
      
      # SPARQL Query Logging
      if ENV['SPARQL_DEBUG'] == 'true' || ENV['SPARQL_LOG'] == 'true'
        log_sparql_query(q, 'interpolated_entity', substitution_hash)
      end
      
      require_relative 'query_executor'
      res = Wikidata::QueryExecutor.execute_simple(q, 'interpolated_entity', {
        task_name: 'client_helpers'
      }) # take the first answer! :/
      while not res.bindings[:same].nil?
        entity = res.bindings[:same].first.to_s.split('/').last
        puts "Properties: you splitting on #{entity}"
        substitution_hash[:interpolated_entity] = entity # must have at least that element
        q = sparql_query % substitution_hash
        res = Wikidata::QueryExecutor.execute_simple(q, 'interpolated_entity_redirect', {
          task_name: 'client_helpers'
        }) # res is result set
      end
      res
    end

    def labels(shadow_id, entity)
      substitution_hash = {interpolated_entity: entity}
      res = interpolated_entity(LABEL, substitution_hash)
      if 0 == res.length
        {linkcount: 0, names_attributes: []}
      else
        {
          linkcount: res.bindings[:linkcount].first.to_i,
           names_attributes: res.collect{|r|
            Name.new(shadow_id: shadow_id, label: r.bindings[:label].to_s, lang: r.bindings[:label].language).attributes
          }
        }
      end
    end

    def datum_instance(entity, property)
      substitution_hash = {interpolated_entity: entity, interpolated_property: property}
      interpolated_entity(DATUM_INSTANCE_, substitution_hash)
    end

    def object(entity_id, property_id)
      require_relative 'query_executor'
      entity = 'Q'+entity_id.to_s
      property = 'P'+property_id.to_s
      q = DATUM_ % {interpolated_entity: entity, interpolated_property: property}
      begin
        # puts q.gsub("\t",'')
        # exit
        res = Wikidata::QueryExecutor.execute_simple(q, 'object_query', {
          task_name: 'client_helpers'
        }) # take the first answer! :/
        while not res.bindings[:same].nil?
          new_entity = res.bindings[:same].first.to_s.split('/').last
          puts "Properties: you splitting on #{new_entity} from #{entity}"
          entity = new_entity
          q = DATUM_ % {interpolated_entity: entity, interpolated_property: property}
          res = Wikidata::QueryExecutor.execute_simple(q, 'object_query_redirect', {
            task_name: 'client_helpers'
          }) # res is result set
        end
        len = res.length
        if len > 1
          ### res = datum_instance(entity, property) # if this doesn't return more than one god help me
          res.each {|rec|
            # puts "---"
            yield rec
          }
        elsif 0 == len
          #
        else
          # puts "+++"
          rec = res.first
          if rec.bindings[:datum].nil?
            # do nothin' (don't store anything)
          else
            ### res = datum_instance(entity, property) # if this returns zero or more than one god help me
            ### rec = res.first
            yield rec
          end
        end
      rescue ActiveRecord::RecordNotUnique => huh
        #... specific error handler
        puts "Record collision: #{rec.inspect}"
      rescue Net::OpenTimeout
        puts q.gsub("\t",'')
        puts "Open Timeout for datum(entity, property) => `datum(#{entity_id}, #{property_id})`"
      rescue Net::ReadTimeout
        puts q.gsub("\t",'')
        puts "Read Timeout for datum(entity, property) => `datum(#{entity_id}, #{property_id})`"
      rescue
        #... catch all error handler
        binding.pry
      else
        #... executes when no error
      ensure
        #... always executed
      end
      len
    end

    def properties(entity)
      begin
        substitution_hash = {interpolated_entity: entity}
        res = interpolated_entity(ATTR_, substitution_hash)
        if res.length > 1
          # how to store multiple result lines? (birth dates or death dates trigger this scenario?)
          # [3] pry(main)> res.bindings[:viaf]
          # => [#<RDF::Literal:0x4a9aebc("268271999")>, #<RDF::Literal:0x4a62710("7524651")>]
          Rails.logger.info "res.length > 1 for entity:#{entity} → res:#{res.inspect}"
        end
        # res.bindings[:"#{entity}Label"].first.to_s
        if 0 == res.length
          {linkcount: 0}
        else
          { # 17
          linkcount:                                         res.bindings[:linkcount].first.to_i,
            floruit: (res.bindings[:floruit].nil?    ? nil : res.bindings[:floruit].first.to_s),
             period: (res.bindings[:period].nil?     ? nil : res.bindings[:period].first.to_s),
             births: (res.bindings[:births].nil?     ? nil : res.bindings[:births].first.to_s), # these have to be plural
             deaths: (res.bindings[:deaths].nil?     ? nil : res.bindings[:deaths].first.to_s), # "
               viaf: (res.bindings[:viaf].nil?       ? nil : res.bindings[:viaf].first.to_s),
            citizen: (res.bindings[:citizen].nil?    ? nil : res.bindings[:citizen].first.to_s),
             gender: (res.bindings[:gender].nil?     ? nil : res.bindings[:gender].first.to_s.split('entity/').last),
      work_lang: (res.bindings[:work_lang].nil?  ? nil : res.bindings[:work_lang].first.to_s.split('entity/').last),
      pub_dates: (res.bindings[:pub_dates].nil?  ? nil : res.bindings[:pub_dates].first.to_s), # must be plural
          title: (res.bindings[:title].nil?      ? nil : res.bindings[:title].first.to_s),
            country: (res.bindings[:country].nil?    ? nil : res.bindings[:country].first.to_s.split('entity/').last),
          copyright: (res.bindings[:copyright].nil?  ? nil : res.bindings[:copyright].first.to_s.split('entity/').last),
              image: (res.bindings[:image].nil?      ? nil : res.bindings[:image].first.to_s),
         britannica: (res.bindings[:britannica].nil? ? nil : res.bindings[:britannica].first.to_s),
          philtopic: (res.bindings[:philtopic].nil?  ? nil : res.bindings[:philtopic].first.to_s),
         philrecord: (res.bindings[:philrecord].nil? ? nil : res.bindings[:philrecord].first.to_s)
          }
          # Date._parse(res.bindings[:birth].first.to_s)
          # => {:zone=>"Z", :hour=>0, :min=>0, :sec=>0, :year=>-550, :mon=>1, :mday=>1, :offset=>0}
        end
      rescue
        binding.pry
      end
    end

    def roles(entity)
      begin
        substitution_hash = {interpolated_entity: entity}
        res = interpolated_entity(ROLE_, substitution_hash)
        if res.length > 1
          # how to store multiple result lines?
          Rails.logger.info "res.length > 1 for entity:#{entity} → res:#{res.inspect}"
        end
        # res.bindings[:"#{entity}Label"].first.to_s
        if 0 == res.length
          {}
        else
          {
               role: (res.bindings[:role].nil?    ? nil : res.bindings[:role]),
               roleLabel: (res.bindings[:roleLabel].nil?    ? nil : res.bindings[:roleLabel])
          }
          # Date._parse(res.bindings[:birth].first.to_s)
          # => {:zone=>"Z", :hour=>0, :min=>0, :sec=>0, :year=>-550, :mon=>1, :mday=>1, :offset=>0}
        end
      rescue
        binding.pry
      end
    end
  end
end