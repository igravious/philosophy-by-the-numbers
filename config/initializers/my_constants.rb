
# https://stackoverflow.com/questions/4110866/ruby-on-rails-where-to-define-global-constants

module GlobalConstants
	BOWER_FOLDER = 'bower_components'.freeze

	DOC_TYPE = 'philosophical text'.freeze
	METADATA = 'metadata'.freeze

	CORPUS_FOLDER = 'tmp'.freeze

	# ontology matrix (search & replace)
	module Unit # OntologyMatrix
		UNKNOWN		= 1
		THING 		= UNKNOWN << 1		# discrete		,	countable
		STUFF			= THING << 1			# continuous	, uncountable
		CONCRETE	= STUFF << 1
		ABSTRACT	= CONCRETE << 1
		CONCEPT 	= ABSTRACT << 1		# firstness?
		ATTRIBUTE = CONCEPT << 1		#	secondness?
		RELATION 	= ATTRIBUTE << 1	# thirdness?
		INSTANCE 	= RELATION << 1
		PROPERTY	= INSTANCE << 1		
		CLASS 		= PROPERTY << 1
		COMMON		=	CLASS << 1
		PROPER		= COMMON << 1
		PHILOSOPHY= PROPER << 1
		HUMANITY	= PHILOSOPHY << 1
		PERSON		= HUMANITY << 1
		GROUP			= PERSON << 1
		SPACE			= GROUP << 1
		PLACE			= SPACE << 1
		REGION		= PLACE << 1
		TIME			= REGION << 1
		EVENT			= TIME << 1
		DURATION	= EVENT << 1
		PROCESS		= DURATION << 1
	end
end

