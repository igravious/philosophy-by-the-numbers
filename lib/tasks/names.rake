namespace :names do

	#
	# need to store aliases
	# need to match on aliases
	#

	def urk
	end

  desc 'demo with one arg'
  task :demo, [:type]  => :environment  do |t, args|
		case args.type
		when 'anto'
			puts "Oh hai Anto!"
		else
			puts "Hello #{args.type}"
		end
  end

  desc 'report how many languages there are'
  task languages: :environment do
		Shadow.none
		puts 'Philosophical Figures'
		# - en_match, no?
		@langs = Name.where(shadow_id: Philosopher.all).group(:lang).pluck(:lang)
		@count_langs = Name.where(shadow_id: Philosopher.all).group(:lang).order('count_all desc').count
		puts "There are #{@langs.size} of them (lexicographically)"
		p @langs
		puts "There are #{@count_langs.size} of them (by frequency)"
		p @count_langs

		puts 'And Their Works'
		# do it all over again
		@langs = Name.where(shadow_id: Work.all).group(:lang).pluck(:lang)
		@count_langs = Name.where(shadow_id: Work.all).group(:lang).order('count_all desc').count
		puts "There are #{@langs.size} of them (lexicographically)"
		p @langs
		puts "There are #{@count_langs.size} of them (by frequency)"
		p @count_langs
  end

	BOUND_VALUE = 'v'.freeze

	ENGLISH_LABEL = "
	PREFIX wd: <http://www.wikidata.org/entity/>
	SELECT ?#{BOUND_VALUE} WHERE {
		wd:%{interpolated_entity} rdfs:label ?#{BOUND_VALUE} FILTER (lang(?#{BOUND_VALUE}) = 'en') .
	}
	".freeze

	def one_label(entity)
		query = ENGLISH_LABEL % {interpolated_entity: entity}
		require 'sparql/client'
		solutions = SPARQL::Client.new('https://query.wikidata.org/sparql', method: :get).query(query)
		# an array of rdf query solutions (should be just one)
		if 1 != solutions.length 
			STDERR.puts "Bad entity: #{entity}"
		else
			label = solutions.first.bindings[BOUND_VALUE.to_sym]
			return label.to_s
		end
		return nil
	end

	desc 'Check which English philosopher names have changed'
	task runny: :environment do
		Shadow.none
		@en_names = Name.where(shadow_id: Philosopher.all, lang: 'en')
		len = @en_names.length
		count = 1
		@en_names.each do |n|
			STDERR.puts "processing #{count} of #{len}"
			p = Philosopher.find(n.shadow_id)
			label = one_label('Q'+p.entity_id.to_s)
			if n.label != label
				STDOUT.puts "#{n.label} => #{label} :: #{n.inspect}"
			end
			count += 1
		end
	end

	in_ = ["'", "(", ")", ",", "-", ".", "0", "1", "2", "3", "4", "5", "8", "9", ":", "·", "À", "Á", "Å", "Ç", "É", "Í", "Ó", "Ö", "Ø", "Ú", "Ü", "Þ", "ß", "à", "á", "â", "ã", "ä", "å", "æ", "ç", "è", "é", "ê", "ë", "ì", "í", "î", "ï", "ð", "ñ", "ò", "ó", "ô", "õ", "ö", "ø", "ú", "ü", "ý", "ā", "ă", "ą", "Ć", "ć", "Č", "č", "Đ", "đ", "Ė", "ė", "ę", "ě", "ğ", "ĩ", "Ī", "ī", "İ", "ı", "Ľ", "Ł", "ł", "ń", "Ō", "ō", "ő", "œ", "ř", "Ś", "ś", "Ş", "ş", "Š", "š", "ţ", "ū", "ů", "ź", "Ż", "ż", "Ž", "ž", "ǧ", "Ș", "ș", "Ț", "ț", "ʹ", "ʻ", "ʾ", "ʿ", "ḍ", "Ḥ", "ḥ", "ṇ", "ṛ", "ṣ", "ṭ", "ạ", "ầ", "ứ", "ự", "‘", "’"]

	out = ["'", "(", ")", ",", "-", ".", "0", "1", "2", "3", "4", "5", "8", "9", ":", "·", "A", "A", "A", "C", "E", "I", "O", "O", "O", "U", "U", "Þ", "ss", "a", "a", "a", "a", "a", "a", "ae", "c", "e", "e", "e", "e", "i", "i", "i", "i", "d", "n", "o", "o", "o", "o", "o", "o", "u", "u", "y", "a", "a", "a", "C", "c", "C", "c", "D", "d", "E", "e", "e", "e", "g", "i", "I", "i", "I", "i", "L", "L", "l", "n", "O", "o", "o", "oe", "r", "S", "s", "S", "s", "S", "s", "t", "u", "u", "z", "Z", "z", "Z", "z", "g", "S", "s", "T", "t", "ʹ", "ʻ", "ʾ", "ʿ", "d", "H", "h", "n", "r", "s", "t", "a", "ầ", "u", "u", "‘", "’"]

  desc 'report how many funny characters there are in "en" as an array of characters'
  task funny: :environment do
		Shadow.none
		@en_names = Name.where(shadow_id: Philosopher.all, lang: 'en')
		h = {}
		@en_names.each do |n|
			funny = false
			n.label.each_char.with_index do |c, idx|
				res = c =~ /[a-zA-Z\s]/
				if res.nil?
					funny = true
					h[c] = true
				end
			end
			if funny
				puts n.label
			end
		end
		puts '---'
		p h.keys.sort
  end

  desc 'organise names based on funny characters there are in "en" (i know, i know)'
  task bunny: :environment do
		in_out = {}
		in_.each_with_index do |c, idx|
			in_out[in_[idx]] = out[idx]
		end
		Shadow.none
		@en_names = Name.where(shadow_id: Philosopher.all, lang: 'en')
		h = {}
		@en_names.each do |n|
			funny = false
			l = n.label.dup
			n.label.each_char.with_index do |c, idx|
				res = c =~ /[a-zA-Z\s]/
				if res.nil?
					funny = true
					h[c] = true
					puts "…#{c}…"
					puts "…#{in_out[c]}…"
					l[idx] = in_out[c] unless in_out[c].nil?
				end
			end
			if funny
				# nobody has a * in their name in any language
				en_match = n.label+'*'+l
				puts "#{n.label} -> #{en_match}"
				res = Name.where(lang: 'en_match', shadow_id: n.shadow_id)
				if res.length == 0
					m = Name.new
					m.label = en_match
					m.lang = 'en_match'
					m.shadow_id = n.shadow_id
					p m
					m.save
				else
					p res
				end
			else
				puts "=#{n.label}"
				res = Name.where(lang: 'en_match', shadow_id: n.shadow_id)
				if res.length == 0
					m = Name.new
					m.label = n.label
					m.lang = 'en_match'
					m.shadow_id = n.shadow_id
					p m
					m.save
				else
					p res
				end
			end
		end
		puts '---'
		p h.keys.sort
  end

	task cap_no_dot: :environment do
		p test
	end
end
