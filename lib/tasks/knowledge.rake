namespace :knowledge do

	desc "how many philosophers does the Google Knowledge Graph have?"
	task google: :environment do
		require 'knowledge'
		# only returns 20!
		res = Knowledge::Google.philosopher_search true
		require 'pry'
		binding.pry
	end
end
