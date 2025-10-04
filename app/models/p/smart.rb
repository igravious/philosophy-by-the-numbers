class P::Smart < ActiveRecord::Base
	self.primary_keys = :redirect_id, :object_id, :type

	def self.property(prop_id)
		Object.const_get("P::P#{prop_id}")	
	end

	def self.dbpedia_property(prop)
		s = prop.split('ontology/').last
	end

	def property_id
		# 0123
		# P::P
		type[4..-1].to_i
	end

	def entity_label
		# Shadow.find_by_entity_id(self.entity_id).names.where(lang: 'en_match').first.label
		rec = Shadow.find_by_entity_id(self.entity_id)
		if rec.nil?
			Rails.logger.info self.inspect
			'!'
		else
			rec = rec.names.where(lang: 'en').first
			if rec.nil?
				Rails.logger.info Shadow.find_by_entity_id(self.entity_id).names
				'?'
			else
				rec.label
			end
		end
	end

	def original_id
		self.entity_id
	end

	def data_id
		self.object_id
	end

	def data_label
		self.object_label
	end

	class ActiveRecord_Relation
		def henry
			self.where('entity_id = redirect_id')
		end
	end
end
