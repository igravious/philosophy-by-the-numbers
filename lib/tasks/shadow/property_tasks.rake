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
    namespace :property do

      desc "SPARQLy property investigations      (check them out only)"
      task :roles, [:cond] => :environment do |task, arg|
        begin
          phils = select(arg.cond)
          exit if phils.nil?
          count = 0
          disp_count = '%03d'
          total = phils.length
          bar = progress_bar(total, FORCE)
          disp_total = '%0'+(total.to_s.length.to_s)+'d'
          num = 0
          Role.delete_all
          phils.each_with_index do |phil, i|
            qQ = "Q#{phil.entity_id}"
            rs = roles(qQ)
            labels = rs[:roleLabel]
            entities = rs[:role]
            q = qQ.ljust(9)
            if labels.nil?
              puts "--- #{q} (#{i})"
            else
              puts "--- #{q} (#{i}) = #{labels.length}"
              labels.each_with_index do |label, idx|
                r = Role.new
                r.shadow_id = phil.id
                r.entity_id = entities[idx].to_s[32..-1].to_i
                r.label = label.to_s
                # p r
                r.save
              end
            end
          end
        rescue
          barf $!, 'shadow:property urk'
          # binding.pry
        end
      end

    end
  end

rescue => e
  barf e, 'shadow property tasks'
  # binding.pry
end