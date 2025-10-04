class MetaFilter < ActiveRecord::Base
	has_many :meta_filter_pairs, :dependent => :restrict_with_error
end
