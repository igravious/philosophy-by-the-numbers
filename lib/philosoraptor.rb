
module Philosoraptor

	BASE_URL='http://version1.api.memegenerator.net/Instance_Create'

	def self.create(top, bottom)

		http_params = {
			username: 'igravious',
			password: 'Mrc%8JtUhX',
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
		rescue Exception => e
			Rails.logger.error "#{e}"
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
			rescue Exception => e
				Rails.logger.error ":( #{e}"
				''
			end
		end

		Rails.logger.info "x #{x}"
		x
	end

end
