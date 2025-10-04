class Name < ActiveRecord::Base
	belongs_to :shadow

	def self.first_shadow_by_lang_order(id)
		self.where(shadow_id: id).order('langorder desc').limit(1).first
	end
	
	def self.rough_label_count(s, skip=false)
		like = " label LIKE \"% #{s} %\" OR label LIKE \"% #{s}\" OR label LIKE \"#{s} %\" OR label = \"#{s}\" "
		key = "LC,#{s}" # should be R_LC
		require 'dalli'
		dc = Dalli::Client.new('localhost:11211')
		begin
			res = dc.get(key)
		rescue
			binding.pry
		end
		if not res.nil? and not skip
			Rails.logger.info "Using cached #{key}"
		else
			a = self.select(:shadow_id).where(like).group(:shadow_id).count
			res = a.delete_if{|k,v| 0==Philosopher.where(id: k).length}
			Rails.logger.info "LC result #{res.inspect}"
			id = dc.set(key, res)
			Rails.logger.info "Caching #{key} as #{id}"
		end
		return res
	end
	def self.exact_label_count(s, skip=false)
		key = "EC,#{s}" # should be E_LC
		require 'dalli'
		dc = Dalli::Client.new('localhost:11211')
		res = dc.get(key)
		if not res.nil? and not skip
			Rails.logger.info "Using cached #{key} which is #{res.inspect}"
		else
			a = self.select(:shadow_id).where(label: s).group(:shadow_id).count
			res = a.delete_if{|k,v| 0==Philosopher.where(id: k).length}
			Rails.logger.info "EC result #{res.inspect}"
			id = dc.set(key, res)
			Rails.logger.info "Caching #{key} as #{id}"
		end
		return res
	end
end
