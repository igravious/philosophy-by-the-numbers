source 'https://rubygems.org'

# http://www.justinweiss.com/articles/what-are-the-differences-between-irb/
#
# irb
# bin/bundle exec irb
# bin/bundle console
# bin/rails console

# http://www.justinweiss.com/articles/how-does-rails-handle-gems/
#
# gems are in default group by default

# Bundle edge Rails instead with: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.11', '>= 4.2.11.3'
gem 'composite_primary_keys', '~> 8'

# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.3.0'

# Use SCSS for stylesheets
gem 'sassc-rails'

# Use Uglifier as compressor for JavaScript assets
# gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
# gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery (2.2.0) as the JavaScript library, and make unobtrusive js jquery_ujs
gem 'jquery-rails' 

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 1.11'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use Cocoon to handle nested forms
gem 'cocoon'

# Use Nokogiri for snarfing XML
gem 'nokogiri', '~> 1.9'

# Party hard
gem 'httparty'

# https://github.com/bokmann/font-awesome-rails
gem "font-awesome-rails"

# pagination
# http://railscasts.com/episodes/254-pagination-with-kaminari
gem 'kaminari'

# http://stackoverflow.com/questions/41207432/expected-string-default-value-for-jbuilder-got-true-boolean-error-in-a
gem 'thor'

# only for rake tasks?
group :task do
	# Snarf hard
	gem 'watir', '~> 6.0'
	gem 'headless'

	# Ruby RDF goodness
	gem 'json-ld'
	gem 'rdf-turtle'
	gem 'rdf-raptor'
	# gem 'sparql'
	gem 'sparql-client'

	# ElasticSearch
	gem 'elasticsearch'

	# WordNet
	gem 'rwordnet'
	#gem 'wordnet-defaultdb'
	#gem 'ruby-wordnet', :github => 'nkpoid/ruby-wordnet' # shite interface

	# Ruby interface to Cayley
	#gem 'cayley', :git => 'https://github.com/igravious/cayley-ruby.git'

	# Guess what
	gem 'rzotero'

	# Ruby interface to ImageMagick
	gem 'rmagick', '~> 4'

	# Play with the _other_ HTTP client library
	gem 'faraday'

	# Pretty colours
	gem 'rouge'

	# Cache API requests
	gem 'api_cache'

	# Key/Value store interface (think Rack for K/V stores)
	gem 'moneta'
	# High performance pure Ruby client for accessing memcached server
	gem 'dalli'

	# git-ruby integration
	gem 'git', '~> 1.7'

	# progress
	gem 'progress_bar'

	# profiling
	gem 'ruby-prof'
end

# Use debugger
# gem 'byebug', group: [:development, :test]
# gem 'ruby-debug-passenger', group: [:development, :test]

group :development, :test do
 # The most awesome Pry
 gem 'pry'

 gem 'ffi-hunspell'
 
 # Call 'byebug' anywhere in the code to stop execution and get a debugger console
 # gem 'byebug'
 
 # Access an IRB console on exception pages or by using <%= console %> in views
 # gem 'web-console', '~> 2.0'

 # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
 # gem 'spring'
end

group :development do
 gem 'web-console'
 gem 'standard'
 gem 'rails-erd'
 # gem 'syntax_tree'
end

group :test do
  gem 'simplecov', '~> 0.17.0', require: false  # Code coverage analysis
  gem 'simplecov-console', require: false       # Terminal output for coverage
end
