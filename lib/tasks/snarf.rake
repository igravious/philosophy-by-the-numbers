require 'watir'
require 'headless'

# https://github.com/mozilla/geckodriver/releases/
#
# put 'em in ~/bin

namespace :snarf do

	desc "Slurp entries from Indiana Philosophy Ontology (InPhO)"
	task inpho: :environment do
		require 'open-uri'
		require 'knowledge'
		require 'cgi'
		include Knowledge
		Shadow.none
		# their api docs: https://www.inphoproject.org/docs/ don't work
		added = 0
		bad_entities = ['Q1075382']
		open('https://www.inphoproject.org/thinker'){|f|
			# https://github.com/sparklemotion/nokogiri/wiki/Cheat-sheet
			doc = Nokogiri::HTML(f)
			# https://www.w3.org/TR/2010/REC-xpath20-20101214/#abbrev
			length = (list = doc.xpath('//div[@id="content"]/ul/li')).length
			# => #(Element:0x2279794 {
			#   name = "li",
			#	  children = [ #(Element:0x2275950 { name = "a", attributes = [ #(Attr:0x22750a4 { name = "href", value = "/thinker/2458" })], children = [ #(Text "Firmin Abauzit")] })]
			#		})
			if length > 0
				thinkers = []
				list.each do |item|
					t = item.child
					thinker = {}
					thinker[:name] = t.child.to_s
					thinker[:href] = t['href']
					thinker[:id] = t['href'].split('/').last.to_i
					phil = Philosopher.find_by(inpho: thinker[:id])
					p phil
					exit
					open("https://www.inphoproject.org/#{thinker[:href]}"){|f1|
						doc1 = Nokogiri::HTML(f1)

						# props
						j = (dts = doc1.xpath('//dl/dt')).length
						(dds = doc1.xpath('//dl/dd')).length
						j.times{|i|
							prop = dts[i].content
							if 'Birth Dates:' == prop
								birth = dds[i].content.strip
								parts = birth.split(' ')
								slice = -1
								flip = 1
								if 'B.C.E.' == parts.last
									slice = -2
									flip = -1
								end
								thinker[:birth] = (parts[slice].to_i)*flip
							elsif 'Death Dates:' == prop
								death = dds[i].content.strip
								parts = death.split(' ')
								slice = -1
								flip = 1
								if 'B.C.E.' == parts.last
									slice = -2
									flip = -1
								end
								thinker[:death] = (parts[slice].to_i)*flip
							elsif 'Nationality/ethnicity:' == prop
								thinker[:nationality] = dds[i].content.strip
							end
						}

						wiki = nil
						if (data = doc1.xpath("//h1[@data-id='#{thinker[:id]}']/following-sibling::p")).length > 0
							data.each do |datum|
								href = datum.child['href']
								parts = href.split('http://wikipedia.org/wiki/')
								if 2 == parts.length
									# really, i should create a snarf file!
									wiki = CGI.unescape parts.last
									ee = Wikipedia::API.wikibase_item({titles: wiki},'')
									if ee.nil?
										puts "#{wiki} ? #{thinker}"
									elsif !bad_entities.include?(ee)
										entity_id = ee[1..-1].to_i
										phil = Philosopher.find_by(entity_id: entity_id)
										# => Philosopher(id: integer, type: string, entity_id: integer, created_at: datetime, updated_at: datetime, linkcount: integer, philosophy: integer, philosopher: integer, metric: float, dbpedia_pagerank: float, routledge: boolean, populate: boolean, dbpedia: boolean, birth: string, death: string, date_hack: string, oxford: boolean, birth_year: integer, death_year: integer, viaf: string, metric_pos: integer, kemerling: boolean, what_label: string, name_hack: string, stanford: boolean, birth_approx: boolean, death_approx: boolean, floruit: string, period: string, runes: boolean, cambridge: boolean, gender: string, internet: boolean, borchert: boolean, measure: float, measure_pos: integer, danker: float, mention: integer, philosophical: integer, philtopic: string, britannica: string, philrecord: string, genre: boolean, obsolete: boolean, inpho: integer)
										if phil.nil?
											phil = Philosopher.new
											phil.entity_id = entity_id
											if thinker.key?(:birth)
												phil.birth_year = thinker[:birth]
											end
											if thinker.key?(:death)
												phil.death_year = thinker[:death]
											end
											# need linkcount, mention, …
											puts "#{ee.ljust(9)} <= #{thinker}"
											added += 1
										else
											puts "#{ee.ljust(9)} => #{thinker[:id]}"
										end
										phil.inpho = thinker[:id]
										phil.save!
									end
									#open("https://en.wikipedia.org/w/api.php?action=query&prop=pageprops&titles=#{parts.last}&format=json"){|f2|
									#	puts f2.read
									#}
								end
							end
						end

						if wiki.nil?
							puts "! #{thinker}"
						end
					}
					thinkers.push(thinker)
				end
				puts "#{length} thinkers in InPhO, added #{added}, made a note of #{length-added}"
				File.write('inpho.json', thinkers.to_json)
			else
				puts "Could not find any thinkers. Check that neither the URL and HTML have changed"
			end
		}
	end

	desc "Additional processing for Dictionary of Philosophical Terms entries"
  task dic_phil_too: :environment do
		headless = Headless.new
		headless.start
		file = ARGV[1]
		browsers = {}
		encountered = {}
		tmp = nil
		File.readlines(file).each do |line|
			#puts line
			splitsville = line.strip.split(' - ')
			url = splitsville.last
			comma = splitsville.first.split(', ')
			if comma.length > 1
				if not encountered.key?(comma[0])
					encountered[comma[0]] = true
				else
					next
				end
			end
			url,a_name = url.split('#')
			#binding.pry
			if not browsers.key?(url)
				#if not tmp.nil?
				#	tmp.quit
				#end
				browsers[url] = Watir::Browser.new
			end
			tmp = browsers[url]
			begin
				#binding.pry
				tmp.goto url
				tmp.a(name: a_name).wait_until_present 13
				foo = tmp.a(name: a_name)
				puts "#{foo.parent.parent.text} - #{url}##{a_name}"
			rescue Watir::Wait::TimeoutError
				puts "! #{line}"
			rescue TypeError
				if a_name.nil?
					begin
						tmp.h2.wait_until_present 13
						foo = tmp.h2.text.gsub("\n",' ')
						puts "#{foo} - #{url}"
					rescue Watir::Wait::TimeoutError => e
						STDERR.puts "Timeout waiting for h2 element at #{url}: #{e.message}"
					end
				else
					puts "? #{line}"
				end
			rescue StandardError => e
				STDERR.puts "Error processing line '#{line}': #{e.message}"
			end
		end
	end

  desc "Slurp entries from A Dictionary of Philosophical Terms and Names (www.philosophypages.com)"
  task dic_phil: :environment do

		headless = Headless.new
		headless.start
		dic = Dictionary.find(1) # hard-coded, ugh
		uri = dic.URI
		uri = uri.split('/')
		uri.pop # get rid of index.htm
		uri = uri.join('/')
		BASE_URL = uri
		pages = {1 => ('a'..'e'), 2 => ('f'..'o'), 3 => ('p'..'z')}
		browsers = {}
		pages.each do |idx,letters|
			letters.each do |letter|
				url = BASE_URL+'/ix'+(idx.to_s)+'.htm#'+letter
				STDERR.puts url
				b = Watir::Browser.new
				b.goto url
				tables = b.tables
				tables.each do |t|
					begin
						if t.summary == letter.upcase
							t.as.each do |el|
								if el.parent.attribute_value('bgcolor').nil?
									if el.text != letter.upcase
										#url = el.href.dup
										#url,a_name = url.split('#')
										#if not browsers.key?(url)
										#	browsers[url] = Watir::Browser.new
										#end
										#tmp = browsers[url]
										#tmp = Watir::Browser.new
										#tmp.goto url
										#tmp.a(name: a_name).wait_until_present
										#begin
										#rescue
										#	STDERR.puts $!
										#	tmp.close
										#	tmp.goto url
										#	tmp.a(name: a_name).wait_until_present
										#end
										#foo = tmp.a(name: a_name)
										#puts "#{foo.parent.parent.text} - #{url}##{a_name}"
										#tmp.close
										puts "#{el.text} - #{el.href}"
									else
										STDERR.puts "-- #{letter.upcase}"
									end
								else
									puts "#{el.parent.b.text}, #{el.text} - #{el.href}"
								end
							end
						end
					rescue
						abort($!)
						# probably should just exit
					end
				end
				b.close
				# p b
			end
			#b.quit
		end

  end # philosophypages task

  desc "Slurp entries from Oxford Dictionary of Philosophy (3rd ed.)"
  task odp_3rd: :environment do

		headless = Headless.new
		headless.start
		dic = Dictionary.find(12)
		uri = dic.URI
		# page 1
		# ?btog=chap&hide=true       &pageSize=100&skipEditions=true&sort=titlesort&source=%2F10.1093%2Facref%2F9780198735304.001.0001%2Facref-9780198735304
		# page 2
		# ?btog=chap&hide=true&page=2&pageSize=100&skipEditions=true&sort=titlesort&source=%2F10.1093%2Facref%2F9780198735304.001.0001%2Facref-9780198735304
		BASE_URL = uri
		pages = (29..35)
		pages.each do |number|
			b = Watir::Browser.new
			url = BASE_URL+'?btog=chap&hide=true'
			page = number==1 ? '' : ('&page='+number.to_s)
			url += "#{page}&pageSize=100&skipEditions=true&sort=titlesort&source=%2F10.1093%2Facref%2F9780198735304.001.0001%2Facref-9780198735304"
			STDERR.puts url
			b.goto url
			(b.h2s :class => "itemTitle").each do |h2|
				entry = h2.text
				if entry =~ /\(.*?\d.*?\)/
					if not (entry =~ /\(\d\d\d\d–\d\d\d\d\)/) and not (entry =~ /\(\d\d\d\d–\d\d\)/)
						entry_href = h2.a.href
						tmp_b = Watir::Browser.new
						tmp_b.goto entry_href
						headword = (tmp_b.span :class => 'headwordInfo').text
						if headword =~ /(\(.+?\))[\.,]?$/
							entry = (entry.split(' (')[0])+' '+$1
						else
							brackets = headword.split(/\)[\.,]? /)
							if 1 == brackets.length
								exit
							end
							entry = (entry.split(' (')[0])+' '+(brackets[0])+')'
						end
						tmp_b.quit
					end
				end
				puts entry
			end
			b.quit
		end

  end # odp task

  desc "Slurp entries from Oxford Dictionary of Philosophy (2nd ed.)"
  task odp_2nd: :environment do

		headless = Headless.new
		headless.start
		dic = Dictionary.find(2)
		uri = dic.URI
		# page 1
		# ?btog=chap&hide=true&pageSize=100&sort=titlesort&source=%2F10.1093%2Facref%2F9780199541430.001.0001%2Facref-9780199541430
		# page 2
		# btog=chap&hide=true&page=2&pageSize=100&sort=titlesort&source=%2F10.1093%2Facref%2F9780199541430.001.0001%2Facref-9780199541430
		BASE_URL = uri
		pages = (1..34)
		pages.each do |number|
			b = Watir::Browser.new
			url = BASE_URL+"?btog=chap&hide=true#{(number==1?'':('&page='+number.to_s))}&pageSize=100&sort=titlesort&source=%2F10.1093%2Facref%2F9780199541430.001.0001%2Facref-9780199541430"
			STDERR.puts url
			b.goto url
			(b.h2s :class => "itemTitle").each do |h2|
				puts h2.text
			end
			b.quit
		end

  end # odp task

  desc "Slurp entries from Philosophy Dictionary, ed. Runes"
  task runes: :environment do

		headless = Headless.new
		headless.start
		dic = Dictionary.find(3) # hard-coded, ugh
		uri = dic.URI
		uri = uri.split('/')
		uri.pop # get rid of index.html
		uri = uri.join('/')
		BASE_URL = uri
		pages = ('a'..'z')
		pages.each do |letter|
			b = Watir::Browser.new
			url = BASE_URL+"/#{letter}.html"
			STDERR.puts url
			b.goto url
			b.as.each do |a|
				if !a.name.blank?
					puts a.name
				end
			end
			b.quit
		end

  end # runes task

  desc "Slurp entries from Routledge Encyclopedia of Philosophy"
  task rep: :environment do

		headless = Headless.new
		headless.start
		dic = Dictionary.find(4)
		uri = dic.URI
		BASE_URL = uri
		pages = (1..144)
		pages.each do |number|
			b = Watir::Browser.new
			url = BASE_URL+"browse/a-z?pageNo=#{number}"
			STDERR.puts url
			b.goto url
			(b.h4s :class => 'result-item__title').each do |h4|
				begin
					puts h4.a.text
				rescue
					puts h4.text
				end
			end
			b.quit
		end

  end # rep task

  desc "Slurp entries from Stanford Encyclopedia of Philosophy"
  task sep: :environment do

		headless = Headless.new
		headless.start
		dic = Dictionary.find(5)
		b = Watir::Browser.new
		url = dic.URI
		STDERR.puts url
		b.goto url
		b.lis.each {|li|
			if 'content' == li.parent.parent.id
				puts li.text.gsub("\n","\n  ") if not li.text.blank?
			end
		}
		b.quit

  end # sep task

  desc "Slurp entries from Internet Encyclopedia of Philosophy"
  task iep: :environment do

		headless = Headless.new
		headless.start
		dic = Dictionary.find(9)
		uri = dic.URI
		BASE_URL = uri
		pages = ('a'..'z')
		pages.each do |letter|
			b = Watir::Browser.new
			url = BASE_URL+"#{letter}/"
			STDERR.puts url
			b.goto url
			ul = b.ul(:class => 'index-list')
			ul.wait_until_present
			els = ul.lis
			els.each do |el|
				entry = el.a.title
				#if 'Aesthetics, Ancient' == entry
				#	binding.pry
				#end
				if el.parent.parent.class == Watir::LI
					puts '- '+entry
				else
					puts entry
				end
			end
			b.quit
		end

  end # iep task

  desc "Slurp entries from Macmillan Ref via encyclopedia.com"
  task borchert: :environment do

		done = false
		initial_page = 21
		start_page = initial_page
		store_current_page = nil
		headless = Headless.new
		headless.start
		dic = Dictionary.find(8)
		BASE_URL = dic.URI
		while not done
			begin
				pages = (start_page..716)
				pages.each do |number|
					store_current_page = number
					b = Watir::Browser.new
					url = BASE_URL+"?page=#{number}/"
					STDERR.puts url
					b.goto url
					ul = b.ul(:class => 'no-bullet-list')
					ul.wait_until_present
					els = ul.lis
					els.each do |el|
						entry = el.a.text
						if entry =~ /\(.+?\)$/
							sub_b = Watir::Browser.new
							sub_url = el.a.href
							sub_b.goto sub_url
							h2 = sub_b.h2(:class => 'doctitle')
							h2.wait_until_present
							if h2.text != entry
								STDERR.puts "OOPS! #{h2.text}"
							else
								div = h2.element(:xpath => './following-sibling::*')
								if "Encyclopedia of Philosophy\nCOPYRIGHT 2006 Thomson Gale" == div.text
									puts entry
								end
							end
							sub_b.close
						end
					end
					b.close
				end # pages
				done = true
			rescue Net::ReadTimeout
				STDERR.puts "URK! Network Timeout"
				start_page = store_current_page
				sleep 20
			rescue Selenium::WebDriver::Error::WebDriverError
				STDERR.puts "OH NOES! Web Driver Error"
				start_page = store_current_page
				sleep 10
			end # rescue
		end # while
		headless.destroy

	end # borchert task

end # namespace 
