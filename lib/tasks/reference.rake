
# bin/rake reference:load odp.txt www.oxfordreference.com

def find_dictionary_by_domain_name name
	dics = Dictionary.all
	dics.each do |d|
		compare = d.URI.split('/')[2]
		return d.id if compare == name
	end
	return nil
end

# https://stackoverflow.com/questions/876396/do-rails-rake-tasks-provide-access-to-activerecord-models

namespace :reference do
	desc "~~"
	task :load, [:file, :work] => :environment do |_, args|
		entries = IO.readlines args[:file]
		# p entries
		dic_id = find_dictionary_by_domain_name args[:work]
		# p dic_id
		if !dic_id.nil?
			Unit.transaction do
				begin
					Unit.delete_all(dictionary_id: dic_id)
					entries.each do |e|
						u = Unit.new
						u.dictionary_id = dic_id
						u.entry = e.rstrip
						u.set_display_name
						u.save!
						pp u
					end
				rescue Exception => e
					msg = "#{e}\nCall tech support!"
					Rails.logger.error msg
					raise ActiveRecord::Rollback, msg
				end
			end
		end
	end
end
