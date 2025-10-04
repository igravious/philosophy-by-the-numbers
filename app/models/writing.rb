class Writing < ActiveRecord::Base
	belongs_to :author
	belongs_to :text

	# this again :( localizable lookup tables
	ROLE=[["Author",1], ["Translator",2], ["Editor",3]]
	AUTHOR=1
	TRANSLATOR=2
	EDITOR=3
end
