
module Philosoraptor

	BASE_URL='http://version1.api.memegenerator.net/Instance_Create'

	def self.create(top, bottom)
		# Fixed: Use security configuration for credential loading
		require_relative 'security_config'
		username = SecurityConfig.load_credential('MEMEGENERATOR_USERNAME')
		password = SecurityConfig.load_credential('MEMEGENERATOR_PASSWORD')

		http_params = {
			username: username,
			password: password,
			languageCode: 'en',
			generatorID: 17,
			imageID: 984,
			text0: top,
			text1: bottom
		}

		begin
			uri = BASE_URL + '?' + http_params.to_query
			# don't need to URI.encode() if you've used to_query()
			#uri = URI.encode(uri)
			#Rails.logger.info(uri)
			require 'open-uri'
			resp = open(uri)
			r = resp.read
			j = JSON.parse(r)
			ret = j['result']['instanceImageUrl']
			return ret
		rescue OpenURI::HTTPError => e
			Rails.logger.error "HTTP error creating meme: #{e.message}"
			'images/onwards.jpg'
		rescue JSON::ParserError => e
			Rails.logger.error "JSON parsing error: #{e.message}"
			'images/onwards.jpg'
		rescue StandardError => e
			Rails.logger.error "Error creating meme: #{e.message}"
			'images/onwards.jpg'
		end
	end

	def self.cache_create(top, bottom)
		require 'moneta'
		store = Moneta.new(:File, dir: 'moneta')
		require 'api_cache'
		APICache.store = store

		x = APICache.get("philosoraptor_create:#{top}:#{bottom}") do
			begin
				y = Philosoraptor::create(top, bottom)
				Rails.logger.info "y #{y}"
				y
			rescue StandardError => e
				Rails.logger.error "Error in cached create: #{e.message}"
				''
			end
		end

		Rails.logger.info "x #{x}"
		x
	end

end
