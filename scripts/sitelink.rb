require 'pry'

# What the hell was this meant to do?

def barf(e, ctx)
	STDERR.puts "#{ctx}: #{$!.inspect} … #{$!.backtrace.first}"
end

def links(plot, avg)
	File.open('links.txt','w') do |f|
		plot.reverse!
		avg.reverse!
		plot.each_with_index do |val, idx|
			place = sprintf("%03d",(plot.length-1)-idx)
			# next if val.nil?
			# count = val.to_s.rjust(4)
			# f.puts "#{idx.to_s.ljust(3)} #{place} #{count}"
			if val.nil?
				count_links = "   0"
				avg_digits = "0"
			else
				count_links = val.to_s.rjust(4)
				avg_digits = sprintf("%3f",((avg[idx]*1.0)/val))
			end
			f.puts "#{place} . #{count_links} #{avg_digits}"
		end
	end
end

PROPS='sitelinks'

def wiki_info(entity)
	# https://www.wikidata.org/w/api.php?action=wbgetentities&format=xml&props=sitelinks&ids=Q868&sitefilter=enwiki
	service_url = 'https://www.wikidata.org/w/api.php'
	http_params = { action: 'wbgetentities', format: 'json', props: PROPS, ids: entity} #, sitefilter: WIKI}
	url = service_url + '?' + http_params.to_query
	require 'open-uri'
	json_resp = open(url)
	if json_resp.status[0] == '200'
		resp = JSON.parse json_resp.read
		if resp['success'] != 1
			raise "Wikidata API query unsuccessful #{resp['error']}"
		end
	else
		raise "Wikidata API query HTTP status #{json_resp.status}"
	end
	resp
	# title = resp['entities'][entity][PROPS][WIKI]['title']
	# title = resp['entities'][entity][PROPS].first[1]['title']
	# site = resp['entities'][entity][PROPS].first[1]['site']
end

def schema_desc(entity)
	w1 = Wikidata::Client.new
	#q = Object.const_get('HITS') % {interpolated_entity: entity}
	q = HITS % {interpolated_entity: entity}
	res = w1.query(q)
	res.bindings[:hits].first.to_i
end

begin
	plot=[]
	avg=[]
	File.foreach(ARGV.first).with_index do |line, idx|
		# 12138  [000] Q15065811 |        ##|           :  (Денисова, Любовь Владиленовна)
		line =~ /(\d+)\s+\[(\d+)\]\s+(Q\d+)\s+\|\s+(#*)\|\s+(.*)\:.+/
		# $~[0]
		links = $~[2].to_i
		digits = $~[3].length.to_i-1
		if plot[links].nil?
			plot[links] = 1
			avg[links] = digits
		else
			plot[links] += 1
			avg[links] += digits
		end
		if $~[5].start_with?('commonswiki')
			puts line
			puts wiki_info($~[3])
		end
	end
	# links(plot, avg)
rescue TypeError
	barf $!, "arg?"
rescue Errno::ENOENT
	barf $!, "file?"
rescue
	barf $!, "urk?"
end
