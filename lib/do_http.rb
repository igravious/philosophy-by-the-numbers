# require 'net/http'
# require 'httparty'
# require 'nokogiri'

class WRAP_HTTP
	# there's a whole bunch of Ruby HTTP clients
	
	def self.do_http2(obj)
		uri = URI.parse(obj.URI)

		support = ''
		if uri.scheme == 'file'
			body = IO.read(uri.path)
			response = {}
			request = {request: "NONE"}
		elsif uri.scheme == 'http' or uri.scheme == 'https'
			g = HTTParty.get obj.URI
			body = g.body
			response = g.headers
			request = {request: "TODO"} # can't figure out how to get the fucking request headers from HTTParty
			Rails.logger.info "body: #{body}" if body.length < 256
			# log the attempt via the calling object
			if obj.log_request(uri: uri.to_yaml, request: request.to_hash.to_yaml, response: response.to_hash.to_yaml)
				if g.response.code.to_i == 200
					support = yield uri, request, response, body
				else
					support = "*sigh* do not yet know how to handle code: #{g.response.code}"
				end
			else
				support = "*sigh* unprocessable_entity: #{obj.log_request_errors.messages}"
			end
		else
			support = "*sigh* unsupported scheme: #{uri.scheme.upcase}"
		end
		support
	end

	# obsolete
	def self.do_http(obj)
		uri = URI.parse(obj.URI)

		support = ''
		if uri.scheme == 'http'
			# http://www.rubyinside.com/nethttp-cheat-sheet-2940.html
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Get.new(uri.request_uri)
			response = http.request(request)
			body = response.body

			# log the attempt via the calling object
			if obj.log_request(uri: uri.to_yaml, request: request.to_hash.to_yaml, response: response.to_hash.to_yaml)
				if response.code.to_i == 200
					support = yield uri, request, response, body
				else
					support = "do not yet know how to handle code: #{response.code}"
				end
			else
				support = "unprocessable_entity: #{obj.log_request_errors.messages}"
			end
		elsif uri.scheme == 'https'
			# http://ruby-doc.org/stdlib-2.2.2/libdoc/net/http/rdoc/Net/HTTP.html#method-i-use_ssl-3D
			support = 'protocol HTTPS unsupported yet'
		else
			support = "unsupported scheme: #{uri.scheme.upcase}"
		end
		support
	end
end
