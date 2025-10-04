class Labeling < ActiveRecord::Base
	belongs_to :tag
	belongs_to :text
end
