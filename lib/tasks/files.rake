namespace :downloaded do
	def foo(s)
		Fyle.find_each do |f|
			if f.type_negotiation == s
				puts "gotcha (#{s}) #{f}"
				# f.cache_file = nil
				# f.save
			end
		end
	end

  desc 'Clear cached content for downloaded philosophical texts by type (pdf, text, xml, html)'
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

  desc 'Report how many downloaded philosophical texts have cached content vs. uncached'
  task report: :environment do
    c = 0
		nc = 0
		Fyle.find_each do |f|
			f.cache_file.blank? ? (nc+=1) : (c+=1)
    end
		puts "cached: #{c}"
		puts "not cached: #{nc}"
  end

  desc 'List downloaded philosophical texts that have no cached content'
  task uncached: :environment do
    uncached_files = []
    Fyle.find_each do |f|
      if f.cache_file.blank?
        uncached_files << f
      end
    end
    
    puts "Found #{uncached_files.count} uncached files:"
    uncached_files.each do |f|
      puts "ID: #{f.id}, URL: #{f.URL}, Type: #{f.type_negotiation}"
    end
  end
end
