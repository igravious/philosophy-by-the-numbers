begin
	def barf(e, ctx)
		STDERR.puts "#{ctx}: #{$!.inspect} … #{$!.backtrace.first}"
	end

namespace :wikidata do

	def cache(term, meros, labels)
		RDF::Writer.open(File.join(Rails.root, 'db', 'wikidata', "meros_#{term}.nt")) { |writer| writer << meros }
		# RDF::Writer.open(File.join(Rails.root, 'db', 'wikidata', "labels_#{args.term}.nt")) { |writer| writer << labels }
		File.open(File.join(Rails.root, 'db', 'wikidata', "labels_#{term}.bin"), 'w') {|file| file.write(Marshal.dump(labels)) }
	end

	desc "Recursively grep term"
	# grep -R
	task :recurse, [:term] => :environment do |task, arg|
		begin
			STDERR.puts Rails.root
			# https://stackoverflow.com/questions/14455884/require-lib-in-rake-task
			# Rake.application.rake_require "#{Rails.root}/lib/wikidata"
			# Rake.application.rake_require "#{Rails.root}/lib/wikidata.rb"
			require 'wikidata'
			w = Wikidata::Client.new
			meros, labels = w.recurse_query(arg.term)
			cache(arg.term, meros, labels)
		rescue
			binding.pry
		end
	end

	desc "Recursively grep multiple terms"
	task :grepify do |task, args| 
		if 0 < args.extras.count
			require 'wikidata'
			w = Wikidata::Client.new # does not accumulate by default
			meros = nil
			labels = nil
    	args.extras.each do |param|
      	meros, labels = w.recurse_query(param)
				cache(param, meros, labels)
			end
    end         
	end

	desc "Utility task for Wikidata file processing"
	task wobble: :environment do
	end

end

rescue
	barf $!, "wikidata urk: $! has wot you want"
	binding.pry
end
