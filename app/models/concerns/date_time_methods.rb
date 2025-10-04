module DateTimeMethods
  extend ActiveSupport::Concern

	#included do
	#	scope :disabled, -> { where(disabled: true) }
  #end

	class_methods do
		def updated_today
			t = Time.zone.now.beginning_of_day
			s = t.to_s.split(' ').first
			self.where("updated_at LIKE '%#{s}%'")
		end
		def updated_this_hour
			t = Time.zone.now.beginning_of_hour
			s = t.to_s.split(':').first
			self.where("updated_at LIKE '%#{s}%'")
		end

		def created_today
			t = Time.zone.now.beginning_of_day
			s = t.to_s.split(' ').first
			self.where("created_at LIKE '%#{s}%'")
		end
		def created_this_hour
			t = Time.zone.now.beginning_of_hour
			s = t.to_s.split(':').first
			self.where("created_at LIKE '%#{s}%'")
		end
  end
end
