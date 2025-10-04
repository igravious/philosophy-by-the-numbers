class Filter < ActiveRecord::Base
	has_many :includings
	accepts_nested_attributes_for :includings, :reject_if => :all_blank, :allow_destroy => true
end
