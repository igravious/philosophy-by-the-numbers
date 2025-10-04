class Expression < ActiveRecord::Base
	# cf
	# class Philosopher < Shadow
	# class Work < Shadow
	belongs_to :work
	belongs_to :philosopher, foreign_key: 'creator_id'

	#=> Expression(creator_id: integer, work_id: integer) 
	def self.compose(p,w)
		Expression.new({creator_id: p.id, work_id: w.id})
	end
end
