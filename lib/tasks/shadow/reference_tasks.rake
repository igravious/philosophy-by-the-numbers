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
    namespace :reference do

      desc "SPARQLy ref work investigations      (of the pageranking variety)"
      task :pagerank => :environment do |task|
        dicts = Dictionary.where.not(entity_id: nil)
        exit if dicts.nil?
        total = dicts.length
        bar = progress_bar(total, FORCE)
        require 'knowledge'
        include Knowledge
        dicts.each do |dict|
          bar.increment! if not bar.nil?
          site,title = Wikidata::API::wiki_title("Q#{dict.entity_id}")
          res = DBpedia::pagerank_of_one_resource title
          begin
            urk = res.bindings[:v].first.to_s.to_f
            dict.update(dbpedia_pagerank: urk)
            q = "Q#{dict.entity_id}".ljust(9)
            t = "#{dict.title}".ljust(50)
            puts "#{t} #{q} #{urk}"
          rescue
            puts "No data for #{title}"
          end
        end
      end

    end # namespace reference
  end # namespace shadow

rescue => e
  barf e, 'shadow reference tasks'
  # binding.pry
end