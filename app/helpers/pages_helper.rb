module PagesHelper
	def table_description(table_name)
		descriptions = {
			'names' => 'Multilingual philosopher/work names and labels',
			'p_smarts' => 'Semantic web triples (DBpedia/Wikidata properties)',
			'properties' => 'Extended semantic properties with inference',
			'roles' => 'Specific role assignments to philosophers',
			'units' => 'Lexical analysis units from term extraction',
			'shadows' => 'Main entities (Philosophers & Works via STI)',
			'obsolete_attrs' => 'Historical canonicity data from old versions',
			'philosopher_attrs' => 'Extended philosopher attributes',
			'viaf_cache_items' => 'Cached VIAF authority file data',
			'expressions' => 'Philosopher-Work relationship links',
			'capacities' => 'Categories/types of philosophical roles',
			'texts' => 'Philosophical texts in the corpus',
			'writings' => 'Author-Text relationship assignments',
			'labelings' => 'Text-Tag associations',
			'fyles' => 'File metadata for corpus documents',
			'http_request_loggers' => 'API request logging',
			'includings' => 'Text-Filter associations for corpus building',
			'metric_snapshots' => 'Historical canonicity calculations',
			'authors' => 'Authors of philosophical texts',
			'canonicity_weights' => 'Algorithm weights for canonicity calculation',
			'dictionaries' => 'Lexical analysis dictionaries',
			'meta_filter_pairs' => 'Complex filtering metadata pairs',
			'meta_filters' => 'Advanced filtering configurations',
			'filters' => 'Text filtering and selection criteria',
			'tags' => 'User-defined tags for texts',
			'resources' => 'External resource references',
			'links' => 'External links and references',
			'work_attrs' => 'Extended work attributes'
		}
		descriptions[table_name] || 'System table'
	end
end
