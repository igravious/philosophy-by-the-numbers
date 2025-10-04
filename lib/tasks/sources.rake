namespace :sources do
	def foo(s)
		Fyle.find_each do |f|
			if f.type_negotiation == s
				puts "gotcha (#{s}) #{f}"
				# f.cache_file = nil
				# f.save
			end
		end
	end

  desc 'urk'
  task :clear, [:type]  => :environment  do |t, args|
		case args.type
		when 'pdf'
			foo ::Fyle::PDF_TEXT
		when 'text'
			foo ::Fyle::PLAIN_TEXT
		when 'xml'
			foo ::Fyle::XML_TEI_TEXT
		when 'html'
			foo ::Fyle::HTML_TEXT
		end
  end

  desc 'Report different sources'
  task report: :environment do
		urls = []
		uniq = []
		Fyle.find_each do |f|
			f.URL =~ /.+\.[a-zA-Z]+\/[a-zA-Z]+\//
			if not urls.include?("#{$~}")
				urls.push("#{$~}")
				f.URL =~ /.+\.[a-zA-Z]+\//
				uniq.push("#{$~}")
			end
		end
		# p urls
		# p uniq
		urls.each_with_index do |u, i|
			# binding.pry
			if uniq.count(uniq[i]) > 1
				urls[i] = uniq[i]
			end
		end
		p urls.uniq
  end
end
