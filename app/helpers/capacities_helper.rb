module CapacitiesHelper

	def c_extra
		{
			label: @label,
			dynamic_count: @dynamic_count,
			only_relevant: on_off(@only_relevant)
		}
	end

end
