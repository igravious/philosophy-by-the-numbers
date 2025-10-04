class P::P31 < P::Smart
	def self.english_label # :/
		'instance of'
	end

	def self.one_long_label(id)
		Array.include ::CoreExtensions::Array::JointPeas
		where(entity_id: id).collect{|r| r.object_label}.unsplat(' / ')
	end
end
