class Tag < ActiveRecord::Base
	has_many :labelings
	has_many :texts, :through => :labelings
	accepts_nested_attributes_for :labelings, :reject_if => :all_blank, :allow_destroy => true
end
