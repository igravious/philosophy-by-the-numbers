CorpusBuilder::Application.routes.draw do
	# meta filter stuff
	resources :meta_filter_pairs do
	end
	namespace :bulk do
		resources :meta_filter_pairs 
	end
	resources :meta_filters do
	end

	# you got the smarts
	namespace :p do
		resources :smarts
	end

	# you got the capacity
	resources :capacities do
		member do
			get 'toggle'
			get 'scribble'
		end
		collection do
			get 'index_count'
			get 'relevant'
		end
	end
	resources :roles

	# your name
	resources :names

	# single table inheritance
	# shadows => philosophers
	# shadows => works
	#resources :shadows
	resources :philosophers do
		collection do
				get 'from_filter/:id', to: 'philosophers#from_filter', as: 'from_filter' # why can't Rails figure the to: and as: out?
				get 'specific'
			patch 'specific'
				get 'compare'
			patch 'compare'
		end
		resources :works
	end
	patch  'philosophers', to: 'philosophers#index', as: 'filter_philosophers'
	resources :works do
		collection do
			get 'stats'
		end
	end

	resources :filters
	resources :labelings
	resources :tags do
		member do
			get 'jump'
		end
	end
	resources :writings
	# don't want all these routes?
	post   'includings' =>       'includings#create'
	delete 'includings',     to: 'includings#uncreate'
	get    'includings/:id', to: 'includings#show', as: 'including'
	delete 'includings/:id', to: 'includings#destroy'

	resources :units do
		collection do
			get 'by_dictionary/:id', to: 'units#by_dictionary', as: 'by_dictionary'
			get 'by_dictionary/:id/what', to: 'units#what', as: 'what'
		end
	end

	resources :dictionaries do
		member do
			get 'entry'
		end
		collection do
			get 'compare'
		end
	end

	resources :resources

	# get 'files/uncached' => 'files#index', as: :uncached
	# get 'files/cached' => 'files#index', as: :cached
	resources :files, as: 'fyles' do
		member do
			get 'cache', to: 'files#show_cache'
			post 'cache', to: 'files#create_cache'
			patch 'save'
			post 'dupe'
			get 'local'
			get 'strip'
			get 'query'
			get 'original'
		end
		collection do
			get 'uncached'
			get 'cached'
			get 'unlinked'
			get 'linked'
		end
	end
	#	patch 'files/:id/cache' => 'files#cache'
	
	# get 'files/:id', to: 'fyles#foo', constraints: { id: /[A-Z]\d{5}/ }, defaults: { format: 'txt' }
	# treats :id_local as all one thing rather than :id and _local
	# get 'files/:id_local', to: 'fyles#plain', constraints: { id: /\d{3}/ }, defaults: { format: 'txt' }, as: 'plain_fyle'
	# defaults: { format: 'foo' } not only does not seem to work but blocks format: foo in url_helper
	# get 'files/:id', to: 'fyles#plain', id: /\d{3}/ , defaults: { format: 'txt' }, as: 'plain_fyle'
	
	get 'files/:n/:id-local/snapshot', to: 'files#snapshotted', id: /\d{3}/, as: 'snapshot_fyle'
	get 'files/:id-local', to: 'files#plainly', id: /\d{3}/, as: 'plain_fyle'
	get 'files/:id-local/chunk', to: 'files#chunked', id: /\d{3}/, chunk: /\d/, as: 'chunk_fyle'

	resources :links

	resources :texts do
		get 'voyant'
		get 'from_fyle', on: :member # TODO rename to ?? (from_file_text_path from_file_new ??)
		collection do
			get 	'excluded'
			get		'included'
			patch '' => 'texts#filtered', as: ''
			get		'archive'
		end
	end

	# get '/:id', to: 'articles#show', constraints: { id: /\d.+/ }
	# get '/:username', to: 'users#show'
	resources :authors do
		# surely be to jesus
		post 'dbpedia', on: :collection, action: :create_dbpedia
		get 'new/dbpedia', on: :collection, controller: :authors, action: :new_dbpedia # new via dbpedia
		get 'new/resource', on: :collection, controller: :authors, action: :new_resource # new via resource
		get 'metadata', on: :member, controller: :authors, action: :show_metadata
		# get 'from_dbpedia', on: :member
	end

	# oh, this pattern again
	# p-p-pages
	get 'info' => 'pages#info' # without a context `info' is meaningless
	get 'export' => 'pages#export'
	get 'welcome' => 'pages#welcome'
	get 'philosoraptor' => 'pages#philosoraptor'
	get 'landing' => 'pages#landing'
	get 'inquiry' => 'pages#inquiry'
	get 'collect' => 'pages#collect' 	# collections of philosophical texts - uh ??
	get 'springy' => 'pages#springy'						# taxonomic
	get 'semantic-web' => 'pages#semantic_web'	# taxonomic
	get 'dracula' => 'pages#dracula'						# taxonomic

	root 'pages#welcome'
	get 'rails/info/schema' => 'info#schema'

	post 'Ctrl-C-Poetry' => 'pages#do_pome', as: 'do_pome'
	get 'Ctrl-C-Poetry' => 'pages#pome'   , as: 'pome'

	post 'paper' => 'pages#do_paper', as: 'do_paper'
	get 'paper' => 'pages#paper'   , as: 'paper'

#post 'search' => 'pages#do_search', as: 'do_search'		# use elasticsearch to search for terms in shapshot n
	get 'search' => 'pages#search'   , as: 'search'			# use elasticsearch to search for terms in shapshot n

	get 'questions' => 'pages#questions'
	get 'questions/irish'
	get 'questions/thinkers'
	get 'questions/birth_places'
	get 'questions/death_places'
	get 'questions/countries'
	get 'questions/schools'
#                Prefix Verb   URI Pattern                                            Controller#Action
	# specific_philosophers GET    /philosophers/specific(.:format)                       philosophers#specific
	#                       PATCH  /philosophers/specific(.:format)                       philosophers#specific
get 'questions/specific', to: 'questions#specific', as: 'specific_questions'
patch 'questions/specific', to: 'questions#specific', as: ''
	get 'questions/interests'
	get 'questions/subjects'
	get 'questions/places'
	get 'questions/all_countries'
	get 'questions/all_places'
	get 'questions/multiplexer'
# Verb URI Pattern                  Controller#Action            Prefix
	get 'questions/from_filter/:id', to: 'questions#from_filter', as: 'from_filter_questions' # why can't Rails figure the to: and as: out?
	get 'questions/instances'
	get 'questions/languages'
	get 'questions/influences'
	get 'questions/upload'
	post 'questions/upload' => 'questions#uploaded'
end
