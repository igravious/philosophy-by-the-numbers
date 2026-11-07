module DateTimeMethods
  extend ActiveSupport::Concern

  def self.extract_year(value)
    string = value.to_s.strip
    return nil if string.empty?
    return string.to_i if string.match?(/\A[+-]?\d+\z/)
    Date._parse(string)[:year]
  rescue ArgumentError, TypeError
    nil
  end

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
