
# https://stackoverflow.com/questions/31965674/has-many-relationship-with-custom-primary-key-not-working

class Capacity < ActiveRecord::Base
	has_many :roles, foreign_key: 'entity_id', primary_key: 'entity_id'

	def toggle_relevant
		if self.relevant
			self.relevant = false
		else
			self.relevant = true
		end
	end

	def self.column_direction(col)
		# determines the original orientation of the columns
		# label is asc A->Z
		# everything else is descending: roles_count highest->lowest, relevant on->off
		%w[label].include?(col) ? 'asc' : 'desc'
	end

end
