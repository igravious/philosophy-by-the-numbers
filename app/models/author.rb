class Author < ActiveRecord::Base
	has_many :writings
	has_many :texts, :through => :writings
	accepts_nested_attributes_for :writings, :reject_if => :all_blank, :allow_destroy => true
	accepts_nested_attributes_for :texts, :reject_if => :all_blank

	def from_dbpedia
		require 'knowledge'
		#Author::is_a_philosopher? self.english_name
		Knowledge::DBpedia::is_a_philosopher? self.english_name
	end
end
