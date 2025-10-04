# external libs

# us

require 'knowledge/version'
require 'knowledge/dbpedia'
require 'knowledge/mediawiki'
require 'knowledge/wikipedia'
require 'knowledge/wikidata'

#require 'knowledge/google'
#require 'knowledge/language_layer'

module Knowledge

	module Format

		def self.verify(entry)
			wn = Knowledge::WordNet
			entry =~ /^([[:upper:]].+)$|^(d'.+)$/ #
			if not $~.nil?
				begin
					if $1.nil?
						terms = $2.dup.split(/[,]? /)
					else
						terms = $1.dup.split(/[,]? /)
					end
				rescue
					binding.pry
				end
				bad_match = 0
				terms.each do |term|
					term =~ /^([[:upper:]]\.)+$/
					if not $~.nil?
						# match initial, ergo defo not a match term
						print ". "
					else
						begin
							if wn::is_common_noun? term
								bad_match += 1
							else
								# matched but not a common noun so pretty famous name prolly
							end
						rescue wn::LemmaNotFound
							# possible name cuz unrecognised
							# possibly cuz functional category which is cool by us for our present purposes
						rescue wn::LemmaPeculiar
							binding.pry
						end
					end
					print "#{term} "
				end
				return [terms, bad_match]
			else
				print ". #{entry} "
				return [[], nil]
			end
		end

	end

	module WordNet

		class LemmaNotFound < StandardError
		end

		class LemmaPeculiar < StandardError
		end

		require 'rwordnet'

		::WordNet::DB.path = File.join(Rails.root, 'WordNet-3.1')

		def self.is_common_noun? term
			down = term.downcase
			lemma = ::WordNet::Lemma.find(down, :noun)
			if lemma.nil?
				print "! " # no match
				raise WordNet::LemmaNotFound
			else
				if lemma.word == down
					if lemma.synsets.first.word_counts.keys[0] == down
						print "_ " # Wordnet internally is lower case so common noun?
						return true
					else
						print "^ " # is upper so proper?
						return false
					end
				else
					print "? " # this suggest strange goings on
					raise WordNet::LemmaPeculiar
				end
			end
		end

		def self.is_lexical? term
			down = term.downcase
			lemma = ::WordNet::Lemma.find_all(down)
			if 0 == lemma.length
				#binding.pry
				raise "not found"
			else
				if lemma.first.word == down
					lemma.first.synsets.each do |s|
						if s.word_counts.keys.include?(down)
							return true
						end
					end
					return false
				else
					raise "peculiar"
				end
			end
		end

	end

	module Google

		def self.entity_search entity
			key = "KG,#{entity}"
			require 'dalli'
			dc = Dalli::Client.new('localhost:11211')
			res = dc.get(key)
			if (!res.nil?)
				Rails.logger.info "Using cached #{key}"
				return res
			end
			api_key = IO.read("#{Rails.root}/.google_api_key").strip
			service_url = 'https://kgsearch.googleapis.com/v1/entities:search'
			http_params = {
				query: entity,
				limit: 1,
				indent: true,
				key: api_key,
			}
			url = service_url + '?' + http_params.to_query
			require 'open-uri'
			json_resp = open(url)
			if json_resp.status[0] == '200'
				resp = JSON.parse json_resp.read
				if resp['itemListElement'].length == 0
					res = ''
				else
					res = resp['itemListElement'][0]['result']
				end
				Rails.logger.info "KG result #{res.inspect}"
				id = dc.set(key, res)
				Rails.logger.info "Caching #{key} as #{id}"
				return res
			else
				raise "Google Knowledge Graph HTTP status #{json_resp.status}"
			end
		end

		def self.philosopher_search force
			key = "KG,philosopher_person"
			require 'dalli'
			dc = Dalli::Client.new('localhost:11211')
			res = dc.get(key)
			if (!res.nil?) and not force
				Rails.logger.info "Using cached #{key}"
				return res
			end
			api_key = IO.read("#{Rails.root}/.google_api_key").strip
			service_url = 'https://kgsearch.googleapis.com/v1/entities:search'
			http_params = {
				query: 'philosopher',
				types: 'Person',
				indent: true,
				key: api_key,
			}
			url = service_url + '?' + http_params.to_query
			require 'open-uri'
			json_resp = open(url)
			if json_resp.status[0] == '200'
				resp = JSON.parse json_resp.read
				res = resp['itemListElement']
				Rails.logger.info "KG result length #{res.length}"
				id = dc.set(key, res)
				Rails.logger.info "Caching #{key} as #{id}"
				return res
			else
				raise "Google Knowledge Graph HTTP status #{json_resp.status}"
			end
		end

	end # module Google

	module LanguageLayer

		def self.detect phrase
			key = "LL,#{phrase}"
			require 'dalli'
			dc = Dalli::Client.new('localhost:11211')
			res = dc.get(key)
			if (!res.nil?)
				Rails.logger.info "Using cached #{key}"
				return res
			end
			api_key = IO.read("#{Rails.root}/.languagelayer_api_key").strip
			service_url = 'http://apilayer.net/api/detect'
			http_params = { access_key: api_key, query: phrase, show_query: 1 }
			url = service_url + '?' + http_params.to_query
			require 'open-uri'
			require 'dalli'
			json_resp = open(url)
			if json_resp.status[0] == '200'
				resp = JSON.parse json_resp.read
				if resp['success'] == true
					res = resp['results']
					Rails.logger.info "KG result #{res.inspect}"
					id = dc.set(key, res)
					Rails.logger.info "Caching #{key} as #{id}"
					return res
				else
					raise "Language Layer unsuccessful #{resp['error']}"
				end
			else
				raise "Language Layer HTTP status #{json_resp.status}"
			end
		end

	end # module LanguageLayer

	module Viaf

		def self.lookup id
			key = "VIAF,#{id}"
			require 'dalli'
			dc = Dalli::Client.new('localhost:11211')
			res = dc.get(key)
			if (!res.nil?)
				Rails.logger.info "Using cached #{key}"
				return res
			end

		end			

	end # module Viaf

end # module Knowledge
