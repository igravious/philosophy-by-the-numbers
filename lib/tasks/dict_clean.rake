#
# useful methods for cleaning the _ dictionary terms
#

namespace :dictionary do
	namespace :clean do

		URL_SEP = ' = '.freeze

		def argf_file
			begin
				STDERR.puts "Found file - #{ARGF.filename}"
			rescue
				STDERR.puts $!
			end
		end

		def skip
			argf_file
			ARGF.skip # skip clean:proper param
			argf_file
		end

		# this works on the philpages (adoptan) format
		desc "are we able to accurately parse every line of the input file"
		task grok: :environment do
			skip
			conform = 0
			file = ARGF.filename
			ARGF.each_with_index do |line, idx|
				splitsville = line.split(URL_SEP)
				# blah - http://
				if splitsville.length != 2
					puts line
					conform += 1
				end
			end
			if conform > 0
				puts "#{conform} deviating from format"
				exit
			end
			longest = 0
			um = File.join(Dir.pwd,file)
			File.readlines(um).each do |line|
				splitsville = line.split(URL_SEP)
				entry, url = splitsville
				if entry.length > longest
					longest = entry.length
				end
			end
			require 'knowledge'
			nam = 0
			tot = 0
			File.readlines(um).each do |line|
				splitsville = line.split(URL_SEP)
				entry, url = splitsville
				# let's get 'em 100% right!
				#print entry.ljust(longest+1)
				date = false
				entry =~ /^(.+) \(.*\d+.*[–]?((.*\d+.*)|([ ]?))\)$/
				if not $~.nil?
					date = true
					puts "@ #{entry}"
					entry = $1.dup
					# do all your database stuff here
				else
					terms, bad_match = Knowledge::Format::verify(entry)
					if 0 == terms.length and bad_match.nil?
						puts ": not checked, but not initially uppercase"
					elsif terms.length == bad_match
						puts ": uppercase, but ordinary term"
					elsif 0 == bad_match
						puts ": possible name or foreign term or technical term"
						nam += 1
					else
						# when in doubt, most likely a term
						puts ": unsure :/"
					end
				end
				tot += 1
			end
		end

		desc "John Smith -> Smith, John | John Smith"
		task proper: :environment do
			skip
			ARGF.each_with_index do |line, idx|
				# print ARGF.filename, ":", idx, ";", line
				words = line.split(' ')
				all_caps = true
				words.each do |word|
					if /[[:upper:]]/.match(word[0]).nil?
						all_caps = false
					end
				end
				if all_caps and words.length > 1
					entry = words.dup
					last = "#{entry.pop},"
					entry.unshift last
					entry = entry.join(' ')
					puts "#{entry} | #{line}"
				else
					puts line
				end
			end
		end

		# do they handle accented characters and non-latin scripts?
		desc "αδιαφορα [adiaphora] -> adiaphora | αδιαφορα [adiaphora]"
		task brackets: :environment do
			skip
			ARGF.each_with_index do |line, idx|
				# print ARGF.filename, ":", idx, ";", line
				if /(\p{Greek}+) \[(\X+)\]/.match(line).nil?
					puts line
				else
					puts "#{$~[2]} | #{line}"
				end
			end
		end

		desc "adiaphora | αδιαφορα [adiaphora] -> adiaphora"
		task strip: :environment do
			skip
			ARGF.each_with_index do |line, idx|
				# print ARGF.filename, ":", idx, ";", line
				if /(\X+) \| (\X+)/.match(line).nil?
					puts line
				else
					puts "#{$~[1]}"
				end
			end
		end

		# i fixed up the file
		# abbrv. -> abbreviation
		desc "Absorption (Abs.) -> Absorption"
		task parens: :environment do
			skip
			ARGF.each_with_index do |line, idx|
				# print ARGF.filename, ":", idx, ";", line
				if /(\X+) \(\X+\)/.match(line).nil?
					puts line
				else
					puts "#{$~[1]} | #{line}"
				end
			end
		end

		# i fixed up the file, could have done it programmatically
		# bam /bar -> bam / bar
		# bam / bar baz -> bam baz / bam bar
		desc "continence / incontinence -> continence"
		task remove_slash: :environment do
			skip
			ARGF.each_with_index do |line, idx|
				# print ARGF.filename, ":", idx, ";", line
				if /(\X+?) \/ (\X+) \| (\X+)/.match(line).nil?
					if /(\X+?) \/ (\X+)/.match(line).nil?
						puts line
					else
						puts "#{$~[1]} | #{line}"
					end
				else
					puts "#{$~[1]} | #{$~[3]}"
				end
			end
		end

		desc "continence/incontinence -> continence / incontinence"
		task align_slash: :environment do
			skip
			ARGF.each_with_index do |line, idx|
				# print ARGF.filename, ":", idx, ";", line
				if /(.+\w)\/(\w.+)/.match(line).nil?
					puts line
				else
					puts line
				end
			end
		end

	end # namespace :clean
end # namespace :dictionary
