class Fyle < ActiveRecord::Base
	# self.table_name = 'fyles'
	has_one :text

	PLAIN_TEXT=1
	XML_TEI_TEXT=2
	PDF_TEXT=3
	HTML_TEXT=4
	GZIP_TEXT=5
	# what in the good god was i thinking
	CONTENT_TYPE=[
		["Plain Text",1],
		["XML (TEI)",2],
		["PDF (text)",3],
		["HTML (text)",4],
		["GZIP (text)",5]
	]
	FILE_EXT=[
		["txt",1],
		["xml",2],
		["pdf",3],
		["html",4],
		["txt.gz",5]
	]
	MIME_TYPE=[
		'',
		'text/plain',
		'application/tei+xml',
		'application/pdf',
		'text/html',
		'text/plain+gzip'
	]

	@http_request_logger=nil

	def log_request(log_params)
		log_params[:caller] = self.to_yaml
		#Rails.logger.info "redundant #{log_params}"
		@http_request_logger = HttpRequestLogger.new(log_params)
		@http_request_logger.save
	end

	def log_request_errors
		@http_request_logger.errors
	end

	require 'do_http'

	def URI
		self.URL
	end

	def snarf
		materialize()[1]
	rescue
		$!.inspect
	end

	#
	# returns an array with two elements
	# 0: the local_file
	# 1: the stripped contents
	#
	def write_binary(name, data)
		# read in binary as well?
		written = -1
		written = File.open(name, 'wb') do |io| # write ASCII-8BIT (i.e. binary?)
			io.write(data)
		end
		Rails.logger.info "(i) w_b #{name} - bytes written - #{written}"
		Rails.logger.info "(i) w_b - *data bytes length* - #{data.bytes.length}"
		written
	end

	def read_binary(name)
		contents = nil
		File.open(name, 'rb') { |io| contents = io.read }
		# how could it be anything other than ASCII_8BIT ?
		Rails.logger.info "(i) r_b from #{name} contents enc #{contents.encoding}"
		# huh? duh
		# contents.force_encoding(Encoding::ASCII_8BIT)
		# Rails.logger.info "(i) r_b force ascii contents enc #{contents.encoding}"
		# how could it be anything other than UTF-8 ?
		Rails.logger.info "(i) r_b model encoding #{self.encoding}"
		# if !encoding.blank?
		#  	contents.force_encoding(encoding) # don't encode, treat it as being already encoded
			# a bit blunt, no?
			# if !contents.valid_encoding?
			# 	contents.scrub!
			# end
		# end
		# force_encoding does not raise/throw an exception
		# https://stackoverflow.com/questions/10200544/ruby-1-9-force-encoding-but-check
		# if e.class == Encoding::UndefinedConversionError and e.message == '"\x92" from ASCII-8BIT to UTF-8'
		contents
	end

	def materialize
		if self.cache_file.blank?
			raise 'Not cached!' # proper specific exception hierarchy
		else
			str = nil
			contents = nil # IO.read(cache_file, "rb")
			if self.local_file.blank? # or self.dirty?
				if self.type_negotiation == ::Fyle::PDF_TEXT
					# PDF's have encoding within 'em
					tmp_file = Fyle::gen_tmp_name('pdftotext-', '.tmp')
					cmd_str = "pdftotext -enc UTF-8 #{cache_file} #{tmp_file}"
					Rails.logger.info "cmd_str #{cmd_str}"
					res = %x(#{cmd_str})
					Rails.logger.info "res #{res}"
					Rails.logger.info " $? #{$?}"
					str = read_binary(tmp_file)
					str.force_encoding('UTF-8')
					if !str.valid_encoding?
						raise "PDF rendered text not valid UTF-8 after requesting it"
					else
						self.encoding = 'UTF-8'
						self.save
					end
				else
					# bit of a waste when the type negotiation is unknown...?
					# must handle compressed files
					contents = read_binary(self.cache_file) # is ASCII_8BIT from this
					if !encoding.blank?
						contents.force_encoding(self.encoding)
						if !contents.valid_encoding?
							if self.encoding == 'UTF-8' and (contents.bytes.select{|a|a==0x92}.length) > 0
								# should make byte sequence checks more rigorous
								Rails.logger.info "says it is UTF-8 but appears (maybe?) to be Windows-1252 cuz of 0x92"
								self.encoding = 'Windows-1252'
								contents.force_encoding(self.encoding)
								self.save
							else
								# figure out other quirks
								raise 'Invalid encoding!' # proper specific exception hierarchy
							end
						end
					end
					if self.type_negotiation == ::Fyle::PLAIN_TEXT
						str = contents.dup
						# <BASE HREF="http://classics.mit.edu/Aristotle/politics.mb.txt"><table border=1 width=100%><tr><td><table border=1 bgcolor=#ffffff cellpadding=10 cellspacing=0 width=100% color=#ffffff><tr><td><font face=arial,sans-serif color=black size=-1>This is <b><font color=#0039b6>G</font><font color=#c41200>o</font><font color=#f3c518>o</font><font color=#0039b6>g</font><font color=#30a72f>l</font><font color=#c41200>e</font></b>'s <a href="http://www.google.com/intl/en_extra/help/features.html#cached">cache</a> of <A HREF="http://classics.mit.edu/Aristotle/politics.mb.txt"><font color=blue>classics.mit.edu/Aristotle/politics.mb.txt</font></a>.<br>
						# <b><font color=#0039b6>G</font><font color=#c41200>o</font><font color=#f3c518>o</font><font color=#0039b6>g</font><font color=#30a72f>l</font><font color=#c41200>e</font></b>'s cache is the snapshot that we took of the page as we crawled the web.<br>
						# The page may have changed since that time.  Click here for the <A HREF="http://classics.mit.edu/Aristotle/politics.mb.txt"><font color=blue>current page</font></a> without highlighting.</font><br><br><center><font size=-2 color=black><i>Google is not affiliated with the authors of this page nor responsible for its content.</i></font></center></td></tr></table></td></tr></table><hr>
						# <html><body><pre>
						str.slice!(/<BASE HREF.+<\/table><hr>/m)
						tmp_file = Fyle::gen_tmp_name('plain-', '.tmp')
					elsif self.type_negotiation == ::Fyle::HTML_TEXT
						doc = Nokogiri::HTML(contents)
						str = doc.xpath('//body').text
						Rails.logger.info "str from Nokogiri and xpath is now encoded #{str.encoding}"
						if self.encoding != str.encoding.name
							Rails.logger.info 'HTML and model encoding differs from Nokogiri and xpath'
							if !str.valid_encoding?
								raise 'Really? That is so unfair'
							else
								self.encoding = str.encoding.name
								self.save
							end
						end
						s_beg=/#{Regexp.escape("var _gaq")}/
						s_end=/#{Regexp.escape("})();")}/
						r = /#{s_beg}.+#{s_end}/m
						str.slice!(r)
						#  $('.dropdown-toggle').dropdown();
  					#
						#
						#
						#  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
						#  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
						#  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
						#  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
						#
						#  ga('create', 'UA-40353515-1', 'stanford.edu');
						#  ga('send', 'pageview');
						s_beg=/#{Regexp.escape("$('.dropdown-toggle'")}/
						s_end=/#{Regexp.escape("'pageview');")}/
						r = /#{s_beg}.+#{s_end}/m
						str.slice!(r)
						tmp_file = Fyle::gen_tmp_name('html-', '.tmp')
					elsif self.type_negotiation == ::Fyle::XML_TEI_TEXT
						# XML has to be UTF-8, if fyle has other encoding then wtf?
						if self.encoding != 'UTF-8'
							Rails.logger.info 'XML but not UTF-8, huh?..'
							contents.force_encoding('UTF-8')
							if !contents.valid_encoding?
								raise "... and can't covert to UTF-8"
							else
								self.encoding = 'UTF-8'
								self.save
							end
						else
							Rails.logger.info 'XML and was set as UTF-8, and checks out as valid'
						end
						doc = Nokogiri::XML(contents)
						str = doc.xpath('//body').text
						if str.encoding != Encoding::UTF_8
							raise "Really? That is so messed up #{str.encoding}"
						end
						tmp_file = Fyle::gen_tmp_name('xml-', '.tmp')
					elsif self.type_negotiation == ::Fyle::GZIP_TEXT
						gz = Zlib::GzipReader.new(StringIO.new(contents))
						# what about encoding?
						str = gz.read.dup
						tmp_file = Fyle::gen_tmp_name('compressed-', '.tmp')
					else # lame-o!
						foo = "Unhandled content!"
						Rails.logger.info "huh? (#{type_negotiation}) #{foo}"
						raise foo
					end
					written = write_binary(tmp_file, str)
				end
				self.local_file = tmp_file
				self.save
			else
				contents = read_binary(self.local_file)
				str = contents.dup
				# should always work, but just in case anybody has changed it on disk badly
				# should checksum it :)
				if !encoding.blank?
					str.force_encoding(self.encoding)
					if !str.valid_encoding?
						raise 'File changed on disk badly?'
					end
				end
			end
			[self.local_file, str]
		end
	end

	def handle_type(response, body)
		Rails.logger.info "handling the ol' type"
		Rails.logger.info "response[content-type]: #{response['content-type']}"
		content_type = response['content-type']
		# TODO handle charset
		ret = ""
		# text/plain; charset=utf-8
		if content_type.starts_with?('text/plain')
			# http://www.davidverhasselt.com/set-attributes-in-activerecord/
			ret = ::Fyle::PLAIN_TEXT
		elsif content_type.starts_with?('text/xml')
			doc = Nokogiri::XML(body)
			if doc.root.name.starts_with?('TEI')
				ret = ::Fyle::XML_TEI_TEXT
			else
				# aaaargh
				ret = "do not know how to random XML content: #{doc.root.name}"
			end
		elsif content_type.starts_with?('application/tei+xml')
			ret = ::Fyle::XML_TEI_TEXT
		elsif content_type.starts_with?('text/html')
			ret = ::Fyle::HTML_TEXT
		elsif content_type.starts_with?('application/pdf')
			ret = ::Fyle::PDF_TEXT
		elsif content_type.starts_with?('application/x-gzip')
			ret = ::Fyle::GZIP_TEXT
		else
			ret = "*sigh* do not yet know how to handle content type: #{response['content-type']}"
		end
		return ret
	end

	def divine_type
		Rails.logger.info "Divining the ol' type"
		WRAP_HTTP::do_http2(self) do |uri, request, response, body|
			content_type = "" # is a string, errors are strings
			content_type = handle_type(response, body) # one of Fyle::FOO strings or dunno string
			return case content_type
			when ::Fyle::PLAIN_TEXT
				# http://www.davidverhasselt.com/set-attributes-in-activerecord/
				self[:handled] = true
				self[:type_negotiation] = ::Fyle::PLAIN_TEXT
				type_in_English
			when ::Fyle::XML_TEI_TEXT
				self[:type_negotiation] = ::Fyle::XML_TEI_TEXT
				type_in_English
			when ::Fyle::HTML_TEXT
				self[:type_negotiation] = ::Fyle::HTML_TEXT
				type_in_English
			when ::Fyle::PDF_TEXT
				self[:type_negotiation] = ::Fyle::PDF_TEXT
				type_in_English
			when ::Fyle::GZIP_TEXT
				self[:type_negotiation] = ::Fyle::GZIP_TEXT
				type_in_English
			else
				Rails.logger.error content_type
				content_type
			end
		end
	end

	def self.gen_tmp_name(name, ext)
		base_name = File.basename(Tempfile.new([name, ext]).path)
		rails_tmp = Rails.root.join('tmp')
		rails_tmp.join(base_name).to_path
	end

	def gen_cache_name(ext)
		name = what.gsub(' ','_')
		_ext = ".#{ext}"
		Fyle::gen_tmp_name(name, _ext)
	end

	# require 'text_filter'

	# new content is (ought to be!) in utf-8, but old is not nececelery
	def save_content(content)
		# done this way for the moment because strip changes aren't version tracked
		if content.blank?
			Rails.logger.info "new content is blank"
			return false
		end
		Rails.logger.info "new content length: #{content.length}"
		Rails.logger.info "new content encoding: #{content.encoding}"
		old_content = read_binary(self.local_file)
		Rails.logger.info "old content length: #{old_content.length}"
		enc = old_content.encoding
		Rails.logger.info "old content encoding: #{enc}"
		Rails.logger.info self.inspect
		if enc != Encoding::UTF_8
			Rails.logger.info "forcing old content to UTF-8 encoding"
			old_content.force_encoding('UTF-8')
			Rails.logger.info "old content encoding: #{old_content.encoding}"
		end
		old_content = content
		if enc != Encoding::UTF_8
			Rails.logger.info "forcing old content to #{enc} encoding"
			old_content.force_encoding(enc)
			Rails.logger.info "old content encoding: #{old_content.encoding}"
		end
		if write_binary(self.local_file, old_content) >= 0
			return true
		else
			return false
		end
	end

	def cache
		# what does do_type return ? [uri, request, response] ?
		cache_name = gen_cache_name(::Fyle::FILE_EXT[type_negotiation-1][0])
		# we have type already... could have changed of course...
		what_happened = WRAP_HTTP::do_http2(self) do |uri, request, response, body|
			# t = TextFilter.new type_negotiation
			Rails.logger.info "(i) cache #{cache_name}"
			str = ''
			Rails.logger.info "(i) cache response['content-type'] #{response['content-type']}"
			Rails.logger.info "(i) cache before str enc #{str.encoding}"
			/(.+);\s?charset=(.+)/ =~ response['content-type']
			foo = $~
			bar = nil
			if !foo.nil?
				bar = $~[2]
			end
			Rails.logger.info "(i) cache $~ #{foo.inspect}"
			Rails.logger.info "(i) cache $~[2] #{bar.inspect}"
			str = body # seems to be always ASCII-8BIT encoded
			Rails.logger.info "(i) cache after = str enc #{str.encoding}"
			Rails.logger.info "(i) cache body enc #{body.encoding}"
			# str.force_encoding(bar)
			str.force_encoding(Encoding::ASCII_8BIT)
			Rails.logger.info "(i) cache force ascii str enc #{str.encoding}"
			# if str.encoding != 'UTF-8'
			# 	str = str.encode('UTF-8')
			# end

			written = write_binary(cache_name, str)
			if written == str.bytes.length
				self[:cache_file] = cache_name
				if !bar.nil?
					self[:encoding] = bar.upcase.gsub('"','') # yup, strip "
				end
				self.save
				return ''
			else
				return 'cache not fully written'
			end
		end
		if what_happened.blank?
			return true
		else
			Rails.logger.info "(i) cache #{what_happened}"
			return false
		end
	end

	def sanitize
	end

	def local
		# url_helpers does not recognise relative_url_root !
		# see: app/controllers/application_controller.rb
		# and: config/initializers/deploy_to_a_subdir.rb
		Rails.application.routes.url_helpers.local_fyle_url(self)
	end

	def strip_url
		# same as above
		Rails.application.routes.url_helpers.strip_fyle_url(self)
	end

	def strip_path
		# same as above
		Rails.application.routes.url_helpers.strip_fyle_path(self)
	end

	# little bit sneakier than the rest
	def plain_url
		# same as above
		Rails.application.routes.url_helpers.plain_fyle_url(id: self.id.to_s.rjust(3, "0"), format: 'txt')
	end

	# little bit sneakier than the rest
	def plain_path
		# same as above
		Rails.application.routes.url_helpers.plain_fyle_path(id: self.id.to_s.rjust(3, "0"), format: 'txt')
	end

	# chunked! for your pleasure
	def chunk_url(c)
		Rails.application.routes.url_helpers.chunk_fyle_url(id: self.id.to_s.rjust(3, "0"), chunk: c, format: 'txt')
	end

	# chunked! for your pleasure
	def chunk_path(c)
		Rails.application.routes.url_helpers.chunk_fyle_path(id: self.id.to_s.rjust(3, "0"), chunk: c, format: 'txt')
	end

	# little bit sneakier than the rest
	def self.snapshot_url(n, id)
		# same as above
		Rails.application.routes.url_helpers.snapshot_fyle_path(n: n, id: id.to_s.rjust(3, "0"), format: 'txt')
	end

	#
	# --- Display Fns
	#
	
	def cached_in_English
		# self.cache_file.blank? ? 'no' : self.cache_file
		# self.cache_file.blank? ? 'no' : File.basename(self.cache_file)
		self.cache_file.blank? ? 'no' : 'yes'
	end

	def localed_in_English
		self.local_file.blank? ? 'no' : 'yes'
	end

	def self.content_type(idx)
		idx.blank? ? "undefined" : ::Fyle::CONTENT_TYPE[idx-1][0]
	end

	def type_in_English
		Fyle::content_type(self.type_negotiation)
	end

	def display_cached
		cached_in_English
	end

	def display_localed
		localed_in_English
	end

	def display_type
		type_in_English
	end

	def display_what
		what
	end

	def display_URL
		url = URI.unescape(self.URL)
		len = self.URL.length
		cut = 24
		(len>((cut*2)+1)) ? ((url[0..(cut-1)])+"…"+(url[-cut..-1])) : url
	end

	def self.linked
		Fyle.where(id: Text.select(:fyle_id).where("fyle_id IS NOT NULL").map(&:fyle_id))
	end

	def self.unlinked
		Fyle.where.not(id: Text.select(:fyle_id).where("fyle_id IS NOT NULL").map(&:fyle_id))
	end

	def self.column_direction(col)
		# determines the original orientation of the columns
		# label is asc A->Z
		# everything else is descending: roles_count highest->lowest, relevant on->off
		%w[].include?(col) ? 'asc' : 'desc'
	end

end
