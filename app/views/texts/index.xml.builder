xml.instruct!
xml.sxf do
	xml.conference :url => '' do
		xml.acronym("PHIL")
		xml.name("Philosophical texts")
		xml.description("Corpus of philosophical texts")
		xml.events do @events.each do |event|
			xml.event :url => event.url, :year => event.year do
				@papers.each_with_index do |paper,i|
      		xml.paper :url => paper.paper_url, :year => paper.year do
						xml.index :value => i+1
						xml.title paper.title
						xml.authors do paper.authors.each do |author|
							xml.author author.name
						end
						end
						if paper.contents
							xml.contents do paper.contents.each do |content|
								xml.content :url => content.url, :size => content.size
							end
							end
						else
							if paper.size
								xml.content :url => paper.content_url, :size => paper.size
								# xml.size paper.size
							else
								xml.content :url => paper.content_url
							end
						end
          end
				end
      end
			end
		end
  end
end


