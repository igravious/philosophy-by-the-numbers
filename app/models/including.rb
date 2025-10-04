class Including < ActiveRecord::Base
	belongs_to :text
	belongs_to :filter
end
