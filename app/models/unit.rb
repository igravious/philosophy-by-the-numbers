class Unit < ActiveRecord::Base
	SYMBOL = []
	# i really have to figure this shit out
	SYMBOL[GlobalConstants::Unit::UNKNOWN]		= ''
	SYMBOL[GlobalConstants::Unit::THING]			= ''
	SYMBOL[GlobalConstants::Unit::STUFF]			= ''
	SYMBOL[GlobalConstants::Unit::CONCRETE]		= ''
	SYMBOL[GlobalConstants::Unit::ABSTRACT]		= ''
	SYMBOL[GlobalConstants::Unit::CONCEPT]		= ''
	SYMBOL[GlobalConstants::Unit::ATTRIBUTE]	= ''
	SYMBOL[GlobalConstants::Unit::RELATION] 	= ''
	SYMBOL[GlobalConstants::Unit::INSTANCE] 	= ''
	SYMBOL[GlobalConstants::Unit::PROPERTY]		= ''
	SYMBOL[GlobalConstants::Unit::CLASS]			= ''
	SYMBOL[GlobalConstants::Unit::COMMON]			=	''
	SYMBOL[GlobalConstants::Unit::PROPER]			= ''
	SYMBOL[GlobalConstants::Unit::PHILOSOPHY]	= ''
	SYMBOL[GlobalConstants::Unit::HUMANITY]		= ''
	SYMBOL[GlobalConstants::Unit::PERSON]			= ''
	SYMBOL[GlobalConstants::Unit::GROUP]			= ''
	SYMBOL[GlobalConstants::Unit::SPACE]			= ''
	SYMBOL[GlobalConstants::Unit::PLACE]			= ''
	SYMBOL[GlobalConstants::Unit::REGION]			= ''
	SYMBOL[GlobalConstants::Unit::TIME]				= ''
	SYMBOL[GlobalConstants::Unit::EVENT]			= ''
	SYMBOL[GlobalConstants::Unit::DURATION]		= ''
	SYMBOL[GlobalConstants::Unit::PROCESS]		= ''

	# should this be in a view helper?
	def tick
		# what_it_is >> 11
		s = ""
		b=1;(1..32).each {|i| s += "<label><input type='checkbox' checked><span class='checkable'>#{SYMBOL[b]}</span></label>" if (self.what_it_is.to_i&b)==b; b = b << 1}
		s
	end

	def search
		pieces = self.entry.split(', ')
		if pieces.length > 1
			"#{pieces[1]} #{pieces[0]}"
		else
			self.entry
		end
	end

	require 'truncate'

	def set_display_name
		self.display_name = truncate self.entry
	end
end
