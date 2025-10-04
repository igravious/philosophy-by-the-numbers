
module Knowledge

	module DBpedia

		module SPARQL

			NAME_IN_SUBJECT =
"
PREFIX db-prop: <http://dbpedia.org/property/>
PREFIX db-ont: <http://dbpedia.org/ontology/>
PREFIX dc-term: <http://purl.org/dc/terms/>
SELECT DISTINCT ?resource
WHERE {
	?resource dc-term:subject ?subj .
	?resource db-prop:name ?name .
	FILTER regex(?name, \"%{name}\", \"i\") .
	FILTER regex(?subj, \"%{subject}\", \"i\") .
}
ORDER BY ?resource
".freeze

			SUBJECT_INFO_OLD =
"
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX wd: <http://www.wikidata.org/entity/>

SELECT DISTINCT ?p ?w ?o
WHERE {
	BIND (wd:%{interpolated_entity} AS ?q)
	?s owl:sameAs ?q .
	?s ?p ?o .
	OPTIONAL {
		?o owl:sameAs ?w .
		FILTER regex(?w, \"wikidata\", \"i\")
	}
}
"

			SUBJECT_INFO =
"
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX wd: <http://www.wikidata.org/entity/>

SELECT DISTINCT ?p ?w ?o
WHERE {
	BIND (wd:%{interpolated_entity} AS ?q)
	?s owl:sameAs ?q .
	?s ?p ?o .
	?o ?foo ?w .
	FILTER regex(?foo, \"wikiPageID$\")
} ORDER BY ?p
"

			PAGERANK_OF_PHILOSOPHERS =
"
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX vrank:<http://purl.org/voc/vrank#>
PREFIX dbo:<http://dbpedia.org/ontology/>

SELECT ?s (SAMPLE(?v) AS ?v) (SAMPLE(?w) AS ?w) (MAX(?bar) AS ?b) (MAX(?foo) AS ?d) 
FROM <http://dbpedia.org> 
FROM <http://people.aifb.kit.edu/ath/#DBpedia_PageRank> 
WHERE {
  ?s rdf:type dbo:Philosopher .
  ?s rdf:type dbo:Person .
  ?s vrank:hasRank/vrank:rankValue ?v .
  ?s foaf:isPrimaryTopicOf ?w .
  OPTIONAL {
    { {?s dbo:birthDate ?b1 .} BIND(year(?b1) as ?bar) } UNION { {?s dbo:birthYear ?b2 .} BIND(year(?b2) as ?bar) }
  }
  OPTIONAL {
    { {?s dbo:deathDate ?d1 .} BIND(year(?d1) as ?foo) } UNION { {?s dbo:deathYear ?d2 .} BIND(year(?d2) as ?foo) }
  }
}
GROUP BY ?s
ORDER BY DESC(?v)
".freeze

			PAGERANK_OF_ONE_RESOURCE =
"
PREFIX vrank:<http://purl.org/voc/vrank#>

SELECT ?s ?v 
FROM <http://dbpedia.org> 
FROM <http://people.aifb.kit.edu/ath/#DBpedia_PageRank> 
WHERE {
	BIND (<http://dbpedia.org/resource/%{interpolated_resource}> as ?s)
	?s vrank:hasRank/vrank:rankValue ?v.
}
".freeze

		end

		require 'rdf'
		DBO_PHILOSOPHICAL_SCHOOL = RDF::URI.new('http://dbpedia.org/ontology/philosophicalSchool')
		# DBP_SCHOOL_TRADITION = RDF::URI.new('http://dbpedia.org/property/schoolTradition')
		
		DBO_MAIN_INTEREST = RDF::URI.new('http://dbpedia.org/ontology/mainInterest')
		# DBP_MAIN_INTERESTS = RDF::URI.new('http://dbpedia.org/property/mainInterests')
		
		DCT_SUBJECT = RDF::URI.new('http://purl.org/dc/terms/subject')
		#
		
		DBO_ERA = RDF::URI.new('http://dbpedia.org/ontology/era')
		# DBP_ERA = RDF::URI.new('http://dbpedia.org/property/era')
		
		DBO_REGION = RDF::URI.new('http://dbpedia.org/ontology/region')
		# DBP_REGION = RDF::URI.new('http://dbpedia.org/property/region')
		
		DBO_INFLUENCED = RDF::URI.new('http://dbpedia.org/ontology/influenced')
		# DBP_INFLUENCED = RDF::URI.new('http://dbpedia.org/property/influenced')
		
		DBO_INFLUENCED_BY = RDF::URI.new('http://dbpedia.org/ontology/influencedBy')
		# DBP_INFLUENCES = RDF::URI.new('http://dbpedia.org/property/influences')

		# hmm, http://www.semantic-web-journal.net/system/files/swj1141.pdf
	
		# need to figure out a smart semantic web caching scheme/framework
	
		def self.is_a_person? name
			key = "people,#{name}"
			require 'dalli'
			dc = ::Dalli::Client.new('localhost:11211')
			res = dc.get(key)
			if (!res.nil?)
				Rails.logger.info "Using cached #{entity}"
				return res
			end
			res = is_in_a_specific_subject? 'people', name
			id = dc.set(key, res)
			Rails.logger.info "Caching #{key} as #{id}"
			res
		end

		def self.is_a_philosopher? name
			key = "philosophers,#{name}"
			require 'dalli'
			dc = ::Dalli::Client.new('localhost:11211')
			res = dc.get(key)
			if (!res.nil?)
				Rails.logger.info "Using cached #{entity}"
				return res
			end
			res = is_in_a_specific_subject? 'philosophers', name
			id = dc.set(key, res)
			Rails.logger.info "Caching #{key} as #{id}"
			res
		end

		def self.entity_property_values entity
			require 'sparql/client'
			sparql = ::SPARQL::Client.new("http://dbpedia.org/sparql")
			query = SPARQL::SUBJECT_INFO % {interpolated_entity: entity}
			result_set = sparql.query(query)
			# Rails.logger.info "DBpedia result #{result_set.inspect}"
			result_set
		end

		def self.is_in_a_specific_subject? subject, name
			require 'sparql/client'
			sparql = ::SPARQL::Client.new("http://dbpedia.org/sparql")
			# SELECT DISTINCT ?resource ?cont
			# should use HERE DOC
			query = SPARQL::NAME_IN_SUBJECT % {name: name, subject: subject}
			result_set = sparql.query(query)
			# Rails.logger.info "DBpedia result #{result_set.inspect}"
			result_set
		end

		def self.pagerank_of_philosophers
			require 'sparql/client'
			sparql = ::SPARQL::Client.new("http://dbpedia.org/sparql")
			query = SPARQL::PAGERANK_OF_PHILOSOPHERS 
			puts query
			exit
			result_set = sparql.query(query)
			#Rails.logger.info "DBpedia result #{result_set.inspect}"
			result_set
		end

		def self.pagerank_of_one_resource res
			require 'sparql/client'
			sparql = ::SPARQL::Client.new("http://dbpedia.org/sparql")
			query = SPARQL::PAGERANK_OF_ONE_RESOURCE % {interpolated_resource: res.gsub(' ','_')}
			puts query
			result_set = sparql.query(query)
			# Rails.logger.info "DBpedia result #{result_set.inspect}"
			result_set
		end

	end # module DBpedia

end
