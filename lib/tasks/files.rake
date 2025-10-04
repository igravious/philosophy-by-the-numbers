namespace :cache do
	def foo(s)
		Fyle.find_each do |f|
			if f.type_negotiation == s
				puts "gotcha (#{s}) #{f}"
				# f.cache_file = nil
				# f.save
			end
		end
	end

  desc 'remove cached files, type is: all, text, pdf, xml, html'
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

  desc 'report how many cached versus uncached'
  task report: :environment do
    c = 0
		nc = 0
		Fyle.find_each do |f|
			f.cache_file.blank? ? (nc+=1) : (c+=1)
    end
		puts "cached: #{c}"
		puts "not cached: #{nc}"
  end
end
