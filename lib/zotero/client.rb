require 'faraday'
require 'json'
require 'set'

# == Zotero Web API v3 Sync Check
#
# Compares a Zotero collection against corpus Fyle records:
# 1. Walks the collection, recursing into subcollections
# 2. Prints items whose URL is not yet in the corpus (with bibliography entry)
# 3. Diffs the URL sets in both directions (Zotero vs Fyle.linked)
#
# == Configuration (via environment, never hardcoded)
# * +ZOTERO_USER_ID+    - numeric user id, see https://www.zotero.org/settings/keys
# * +ZOTERO_API_KEY+    - private API key, library read access suffices
# * +ZOTERO_COLLECTION+ - top-level collection name, case-insensitive
#                         (default: "emerging philosophy")
#
# Values come from the process environment; as a fallback a .env file in
# the project root is loaded (gitignored, see .env.template).
#
# == Usage
#   bin/rails runner lib/zotero.rb
#
# Loading this file is side-effect free: no API calls and no env mutation
# (load_env_file touches ENV only when explicitly called). The sync runs
# only via the lib/zotero.rb script wrapper.
#
# https://www.zotero.org/support/dev/web_api/v3/basics

module Zotero
	Base_URL = 'https://api.zotero.org'
	API_Version = 3
	Default_Collection = 'emerging philosophy'
	Per_Page = 100

	# Minimal .env loader (this stack has no dotenv gem). Never overrides
	# variables already present in the environment.
	#
	# @param path [String, nil] defaults to .env in the project root
	# @return [void]
	def self.load_env_file(path = nil)
		path ||= begin
			root = defined?(Rails) && Rails.respond_to?(:root) && Rails.root ? Rails.root.to_s : File.expand_path('../..', __dir__)
			File.join(root, '.env')
		end
		return unless File.exist?(path)

		File.foreach(path) do |line|
			line = line.strip
			next if line.empty? || line.start_with?('#')
			key, sep, value = line.partition('=')
			next if sep.empty?
			key = key.strip
			value = value.strip.sub(/\A"(.*)"\z/m, '\1').sub(/\A'(.*)'\z/m, '\1')
			ENV[key] = value if ENV[key].to_s.empty?
		end
	end

	# Credentials via the shared SecurityConfig pattern (as in lib/philosoraptor.rb).
	#
	# @return [Hash] +:user_id+ and +:api_key+
	# @raise [RuntimeError] if a credential is unset
	def self.credentials
		{
			user_id: SecurityConfig.load_credential('ZOTERO_USER_ID'),
			api_key: SecurityConfig.load_credential('ZOTERO_API_KEY')
		}
	end

	# Authenticated connection to the Zotero API.
	#
	# @param api_key [String]
	# @return [Faraday::Connection]
	def self.connection(api_key)
		Faraday.new(url: Base_URL) do |faraday|
			faraday.headers['Zotero-API-Version'] = API_Version.to_s
			faraday.headers['Authorization'] = "Bearer #{api_key}"
			faraday.adapter Faraday.default_adapter
		end
	end

	# Fetches every page of a paginated Zotero endpoint, following
	# Link: rel="next" headers.
	#
	# @param conn [Faraday::Connection]
	# @param path [String] request path, or absolute URL as found in Link headers
	# @yield [Array] each page's parsed JSON array
	# @raise [RuntimeError] on non-success HTTP status
	def self.paged_get(conn, path)
		url = path
		until url.nil?
			response = conn.get(url)
			raise "Zotero API error #{response.status}: #{response.body}" unless response.success?
			yield JSON.parse(response.body)
			link = response.headers['link']
			url = link && link[/<([^>]+)>;\s*rel="next"/, 1]
		end
	end

	# Finds a top-level collection by name (case-insensitive).
	#
	# @param user_id [String]
	# @param name [String]
	# @return [Hash, nil] the collection object, or nil if not found
	def self.find_collection(conn, user_id, name)
		found = nil
		paged_get(conn, "/users/#{user_id}/collections/top?limit=#{Per_Page}") do |colls|
			found ||= colls.find { |c| c['data']['name'].to_s.casecmp?(name) }
		end
		found
	end

	# Yields each page of items in a collection, recursing into subcollections.
	#
	# @param coll_key [String] collection key
	# @yield [Array] each page of item objects (include=data,bib)
	def self.each_items_page(conn, user_id, coll_key, &block)
		paged_get(conn, "/users/#{user_id}/collections/#{coll_key}/items?include=data,bib&limit=#{Per_Page}", &block)
		paged_get(conn, "/users/#{user_id}/collections/#{coll_key}/collections?limit=#{Per_Page}") do |subs|
			subs.each { |sub| each_items_page(conn, user_id, sub['key'], &block) }
		end
	end

	# Runs the sync comparison and prints the report.
	#
	# @param collection_name [String, nil] overrides ZOTERO_COLLECTION
	# @return [void]
	def self.sync_report(collection_name = nil)
		load_env_file
		creds = credentials
		collection_name = collection_name.to_s.strip
		collection_name = ENV['ZOTERO_COLLECTION'].to_s.strip if collection_name.empty?
		collection_name = Default_Collection if collection_name.empty?

		conn = connection(creds[:api_key])
		coll = find_collection(conn, creds[:user_id], collection_name)
		raise "Collection '#{collection_name}' not found among top-level Zotero collections" if coll.nil?

		puts "Collection: #{coll['data']['name']} (#{coll['key']}), including subcollections"

		known_urls = Set.new(Fyle.where.not(URL: nil).pluck(:URL))
		puts "#{known_urls.size} URLs on file in the corpus"

		urls = []
		seen = Set.new
		total = 0
		no_url = 0
		each_items_page(conn, creds[:user_id], coll['key']) do |items|
			items.each do |item|
				next unless seen.add?(item['key'])
				next if item['data']['itemType'] == 'attachment'
				total += 1
				url = item['data']['url'].to_s.strip
				if url.empty?
					no_url += 1
					puts "(no URL) #{item['bib']}"
				elsif known_urls.include?(url)
					urls << url
				else
					puts "#{url}\n#{item['bib']}"
				end
			end
		end
		puts "#{total} non-attachment items in Zotero collection, #{no_url} without URL, #{urls.size} already in corpus"

		base_urls = Fyle.linked.map(&:URL).compact.sort
		urls = urls.sort

		puts "corpus (linked) - #{base_urls.length}"
		puts "zotero - #{urls.length}"

		if base_urls.length > urls.length
			puts "corpus > zotero, diffing …"
			puts base_urls - urls
		elsif base_urls.length == urls.length
			puts "Same quantity, diffing …"
			puts base_urls - urls
		else
			puts "corpus < zotero, diffing …"
			puts urls - base_urls
		end
	end
end
