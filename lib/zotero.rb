
require 'faraday'

module Zotero
	Base_URL = 'https://api.zotero.org'
	API_Version = {query_param: 'v', query_string: 3}
	API_Key = {userID: 1248965,key: 'L4KkWh4aGygSjJUz98vXWUIX'}
end

# https://www.zotero.org/support/dev/web_api/v3/basics

conn = Faraday.new(:url => Zotero::Base_URL) do |faraday|
	# faraday.request  :url_encoded	# form-encode POST params
	faraday.headers['Zotero-API-Version'] = Zotero::API_Version[:query_string].to_s
	faraday.headers['Authorization'] = "Bearer #{Zotero::API_Key[:key]}"
	# faraday.response :logger                  # log requests to STDOUT
	faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

response = conn.get "/users/#{Zotero::API_Key[:userID]}/collections/top"

collections = JSON.parse(response.body)

idx = nil
collections.each_with_index do |coll,i|
	if coll["data"]["name"] == "PACT.x"
		idx = i
	end
end

# pp collections[idx]

get = "/users/#{Zotero::API_Key[:userID]}/collections/#{collections[idx]['key']}/items"
urls = []
begin
	response = conn.get "#{get}?include=data,bib"
	link = response.headers['link']
	items = JSON.parse(response.body)

	puts "#{items.length} in this part of the PACT.x collection"

	items.each_with_index do |item, i|
		url = item["data"]["url"]
		type = item["data"]["itemType"]
		bib = item["bib"]
		if type != "attachment"
			if Fyle.where(url: url).empty?
				puts "#{sprintf("%03d",i)} - #{url}\n#{bib}"
			else
				urls <<= url
			end
		end
	end

	idx = (link =~ /.*<(.+)>; rel=\"next\"/)
	break if idx.nil?
	get = $~[1]
end until false

base_urls = Fyle.linked.map {|f| f.URL}
base_urls = base_urls.sort
urls = urls.sort

puts "PACT.x - #{base_urls.length}"
puts "zotero - #{urls.length}"

if base_urls.length > urls.length
	puts "PACT.x > Zotero, diffing …"
	puts base_urls - urls
elsif base_urls.length == urls.length
	puts "Same quantity, diffing …"
	puts base_urls - urls
else
	puts "PACT.x < Zotero, diffing …"
	puts urls - base_urls
end

