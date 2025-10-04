
module Knowledge

	module Wikipedia

		module API

			WIKIBASE='wikibase_item'
			PAGEPROPS='pageprops'

			# this should be in knowledge.rb and it should be cached
			def self.wikibase_item(key_value_pair, lang='en')
				my_key = key_value_pair.keys[0]
				my_value = key_value_pair.values[0]
				key = "WB,#{my_value}" # key prefix
				require 'dalli'
				dc = Dalli::Client.new('localhost:11211')
				resp = dc.get(key)
				if not resp.nil?
					Rails.logger.info "Using cached #{key}"
				else
					# the different part
					if lang.empty?
						service_url = "https://wikipedia.org/w/api.php"
					else
						service_url = "https://#{lang}.wikipedia.org/w/api.php"
					end
					http_params = {action: 'query', format: 'json', prop: PAGEPROPS, ppprop: WIKIBASE, redirects: 1, my_key => my_value}
					url = service_url + '?' + http_params.to_query
					require 'open-uri'
					json_resp = open(url)
					resp = if '200' == json_resp.status[0]
						begin
							tmp = JSON.parse json_resp.read
							raise tmp['warnings']['main'] if tmp.key?('warnings')
							page = nil
							page = tmp['query']['pages'].first
							page[1][PAGEPROPS][WIKIBASE]
						rescue
							# um, can't figure out what comobo of exception handling and return values and output to use
							#puts "# WB::‘#{value}’ – #{tmp}"
							STDERR.puts $!
							STDERR.puts "# WB::‘#{my_key} => #{my_value}’ – #{page}"
							nil
						end
					else
						raise "Wikipedia API query HTTP status #{json_resp.status}"
					end
					
					if not resp.nil?
						Rails.logger.info "WB result #{resp.inspect}"
						id = dc.set(key, resp)
						Rails.logger.info "Caching #{my_key} as #{id}"
					end
				end
				return resp
			end

		end # module API

	end # module Wikipedia

end # module Knowledge
