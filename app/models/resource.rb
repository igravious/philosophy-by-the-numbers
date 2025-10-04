class Resource < ActiveRecord::Base

	def metadata
		require 'sparql/client'
		sparql = SPARQL::Client.new("http://dbpedia.org/sparql")
		# SELECT DISTINCT ?resource ?cont
		#  <#{self.URI}> db-prop:name             ?nam .
		query =
		"
		PREFIX db-prop: <http://dbpedia.org/property/>
		PREFIX db-ont: <http://dbpedia.org/ontology/>
		PREFIX dc-term: <http://purl.org/dc/terms/>
		PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
		SELECT (group_concat(?dob ; separator = \"\") as ?dob) (group_concat(?dod ; separator = \"\") as ?dod) (group_concat(?abs ; separator = \"\") as ?abs) (group_concat(?alt ; separator = \"\") as ?alt) (group_concat(?nam ; separator = \"\") as ?nam) (group_concat(?nat ; separator = \"\") as ?nat)
		WHERE { {
		  <#{self.URI}> db-prop:dateOfBirth      ?dob .
		  FILTER(str(?dob))
		} UNION {
		  <#{self.URI}> db-prop:dateOfDeath      ?dod .
		  FILTER(str(?dod))
		} UNION {
		  <#{self.URI}> db-prop:alternativeNames ?alt .
		  FILTER(lang(?alt) = \"en\")
		} UNION {
		  <#{self.URI}> rdfs:label               ?nam .
		  FILTER(lang(?nam) = \"en\")
		} UNION {
		  <#{self.URI}> db-prop:nationality      ?nat .
		  FILTER(str(?nat))
		} UNION {
		  <#{self.URI}> db-ont:abstract          ?abs .
		  FILTER(lang(?abs) = \"en\")
		} }
		"
		result_set = sparql.query(query)
		Rails.logger.info "result #{result_set.inspect}"
		result_set[0]
	end
end
