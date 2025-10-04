#
# useful methods for cleaning the _ dictionary terms
#

module WordNet

end


namespace :units do

	def is_proper? unit
		the_sub_entries = unit.entry.split(' ')
		is_proper = true
		the_sub_entries.each { |sub_entry|
			if (sub_entry =~ /^[[:upper:]][[:lower:]]+$/).nil?
				is_proper = false
				break
			end
		}
		is_proper
	end

	require 'pry'
	require 'rwordnet'

	def is_common_noun? term
		down = term.downcase
		lemma = WordNet::Lemma.find(down, :noun)
		if lemma.nil?
			print ". " # no match
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
				raise WordNet::LemmaMismatch
			end
		end
	end

	def process id
		require 'knowledge'
		units = Unit.where(dictionary_id: id)
		units.each do |unit|
			# GlobalConstants::Unit::PHILOSOPHY
			if is_proper? unit
				print unit.entry.ljust(42)
				begin
					c = is_common_noun? unit.entry
					msg = ""
				rescue Exception => e
					# puts ": Needs further WordNet investigation. #{e}"
					c = false
					msg = "(#{e})"
				end
				begin
					if c
						unit.what_it_is = GlobalConstants::Unit::COMMON | GlobalConstants::Unit::ABSTRACT
						puts ": Common (abstract) noun masquerading as a proper noun?"
					else
						sol = Knowledge::DBpedia::is_a_philosopher? unit.entry
						if 1 == sol.length and sol.first.is_a? RDF::Query::Solution
							# PERSON + PHILOSOPHY = PHILOSOPHER
							unit.what_it_is = GlobalConstants::Unit::PERSON | GlobalConstants::Unit::INSTANCE | GlobalConstants::Unit::PHILOSOPHY
							puts ": Looks like we have ourselves a philosophical figure?"
						else
							sol = Knowledge::DBpedia::is_a_person? unit.entry
							if 1 == sol.length and sol.first.is_a? RDF::Query::Solution
								unit.what_it_is = GlobalConstants::Unit::PERSON | GlobalConstants::Unit::INSTANCE
								puts ": We appear to have ourselves a person?"
							else
								# could be:
								# person related to philosophy or of philosophical interest
								# 	`the historical Aristotle'
								# 	`Aristotelian'
								# 	`Aristotelianism'
								# 	`an Aristotle'
								# or a place …
								# or an event …
								# or a social entity …
								#
								# so if it's not a common noun masqueraing as a proper noun,
								# then it may be a legit proper noun, and if it's not a person
								# (whether a philosopher or not) and it is in WordNet then
								# we need to explore DBpedia further
								#
								# (either:
								# 	the person/philosopher is not listed, or
								# 	it's a major place, major event, major social entity, or
								# 	it's an adjectival version, or
								#		it being used as an ism or such like, or
								#		…
								# 	)
								#
								res = Knowledge::Google::entity_search unit.entry
								if !res.nil? and res['@type'].any? { |t|
										if t == 'Person'
											true
										else
											false
										end
									}
									if res['description'] =~ /Philosopher/
										unit.what_it_is = GlobalConstants::Unit::PERSON | GlobalConstants::Unit::INSTANCE | GlobalConstants::Unit::PHILOSOPHY
										puts ": Knowledge Graph reckons 'tis a philosopher?"
									else
										unit.what_it_is = GlobalConstants::Unit::PERSON | GlobalConstants::Unit::INSTANCE
										puts ": Knowledge Graph reckons 'tis a person?"
									end
								else
									res = Knowledge::LanguageLayer::detect unit.entry
									puts ": LanguageLayer => #{res[0]['language_code']}"
									unit.what_it_is = GlobalConstants::Unit::PROPER
								end
							end
						end
					end
					unit.save!
				rescue Exception => e
					msg = "#{e}"
					puts ": #{msg}"
					Rails.logger.info "huh? #{msg}"
				end
			end
		end
	end


		desc "normalise a single or multiple or all units"
		task :normalise, [:ids] => :environment do |normalise, args|
			#skip
			if !args.ids.nil?
				if args.ids == 'all'
					puts "use with caution"
				else
					puts "id: #{args.ids}"
					process args.ids
					if 0 < args.extras.count
						args.extras.each do |param|
							puts "id: #{param}"
							process param
						end
					end
				end
			else
				puts "no params"
			end
		end

		namespace :all do
			desc ''
			task all: :environment do
			end
		end

end # namespace :units
