
# https://stackoverflow.com/questions/31965674/has-many-relationship-with-custom-primary-key-not-working

class Role < ActiveRecord::Base
	belongs_to :shadow
	belongs_to :capacity, primary_key: 'entity_id', foreign_key: 'entity_id', counter_cache: true
end

