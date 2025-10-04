class Shadow < ActiveRecord::Base
	has_many :names, :dependent => :destroy

	accepts_nested_attributes_for :names

	include DateTimeMethods

	def get_year(date_sym)
		y = nil
		if not self[date_sym].blank?
			 y = Date._parse(self[date_sym])[:year].to_i
		end
		y
	end

	def do_q(the_sym)
	end

	def year(date_sym)
		begin
			approx = (date_sym.to_s+'_approx').to_sym
			if self[date_sym].blank?
				nil
			elsif self[approx]
				self[date_sym].to_i
			else
				boom = self[date_sym].split(';')
				Date._parse(boom[0])[:year]
			end
		rescue
			nil
		end
	end

	def english
		res = self.names.find_by(lang: 'en')
		if res.nil?
			''
		else
			res[:label]
		end
	end

	def show_label(lang, individual)
		#Rails.logger.info shadow.inspect
		if 'all' == lang
			if individual
				s = Name.where(shadow_id: self.id).order('langorder desc').limit(1).first # TODO pick one fairly arbitrarily, should attempt to guess! (by article size?)
				if s.nil?
					Rails.logger.warn "Philosopher.find(#{self.id}) needs a label"
					w_label = en_label = label = "Q#{self.entity_id}" # TODO what should label, w_label, and w_lang be in this case?
					w_lang = '*'
				else
					label   = "#{s.label}@#{s.lang}"
					w_label = s.label
					w_lang  = s.lang
				end
			else
				label   = "#{self.label}@#{self.lang}"
				w_label = self.label
				w_lang  = self.lang
			end
		else
			#self.viaf.nil? ? self.label : (link_to self.label, "http://viaf.org/viaf/#{self.viaf}/rdf.xml")
			# this is to enable better matching on search: Paul Ricœur*Paul Ricoeur
			# quite simple and clever if you ask me
			Rails.logger.warn self.inspect
			w_label, label = self.label.split('*')
			label = w_label if label.nil?
			w_lang = lang
		end
		begin
			en_label = Name.find_by(shadow_id: self.id, lang: 'en').label
		rescue
			Rails.logger.warn "Philosopher.find(#{self.id}) needs an English label"
			en_label = "…"
		end
		[w_label, w_lang, en_label, label]
	end

	def self.column_direction(col)
		%w[entity_id label].include?(col) ? 'asc' : 'desc'
	end
end

# class Philosopher < Shadow; end

# https://medium.com/@jbmilgrom/active-record-many-to-many-self-join-table-e0992c27c1e
	
class Philosopher < Shadow
	# source: :work matches with the belongs_to :work in the Expression join model 
	has_many :works, through: :route_a, source: :work
	# route_a “names” the X join model for accessing through the work association
	has_many :route_a, foreign_key: :creator_id, class_name: "Expression"

	def join_attribute
		{creator_id: self.id}
	end
	
	#def mentions
	#	begin
	#		self.philosopher + self.philosophy
	#	rescue
	#		0
	#	end
	#end
	
	def capacities
		Capacity.where(entity_id: Role.where(shadow_id: self.id).pluck(:entity_id))
	end
	
	def relevant? # Hmm, make more sophisticated
		#if Role.where(shadow_id: self.id, label: 'natural philosophy').length == 1
		#	false
		#else
		#	true
		#end
		self.capacities.pluck(:relevant).any?{|x|x==true}
	end

	def birth_death
		begin
			b = self.year(:birth)
			d = self.year(:death)
			# handle nil
			if b.nil? and d.nil?
				'(0)'
			elsif d.nil?
				if b < 0 # b is not nil
					b = b.abs.to_s+" BCE"
				end
				"(b. #{b})"
			elsif b.nil?
				if d < 0 # d is not nil
					d = d.abs.to_s+" BCE"
				end
				"(d. #{d})"
			else
				if d < 0 # then b must be < 0 as well
					b = b.abs
					d = d.abs.to_s+" BCE"
				elsif b < 0 # but d isn't
					b = b.abs.to_s+" BCE"
					d = d.abs.to_s+" CE"
				end
				"(#{b}–#{d})"
			end
		end
	end

	def self.phil_null
		self.where('philosophy IS NULL AND philosopher IS NULL')
	end

	def self.nuke_all_date_hack
		self.where.not(date_hack: nil).update_all(date_hack: nil)
	end

	def self.repo # I M I C K W O R D S
		self.where(inphobool: false, borchert: false, internet: false, cambridge: false, kemerling: false, populate: false, oxford: false, routledge: false, dbpedia: false, stanford: false)
	end
end

class Work < Shadow
	# `source: :creator' matches with the belongs_to :creator in the Expression join model 
	has_many :creators, through: :route_b, source: :philosopher
	# `route_b' “names” the X join model for accessing throught the work association
	has_many :route_b, foreign_key: :work_id, class_name: "Expression"

	def join_attribute
		{work_id: self.id}
	end

	def obsolete_phil_label(phils, lang)
		phils = phils.select('shadows.*, names.lang, names.label').joins(:names).where('lang = ?', lang)
		if phils.length > 2
			phil_label = (phils[0..1].collect{|phil| (phil.show_label(lang, true)[3])+'('+phil.measure_pos.to_s+')'})
			phil_label = phil_label.join(', ')+' …'
		else
			phil_label = phils.collect{|phil| (phil.show_label(lang, true)[3])+'('+phil.measure_pos.to_s+')'}
			phil_label = phil_label.join(', ')
		end
		phil_label.gsub(' ','&nbsp;')
		#phil_label = phil_label[0..35]+' …' if phil_label.length > 50
		#phil_label = phil_label.gsub(' ','&nbsp;')
	end

	def phil_label(phils, lang)
		lang = 'en' if lang == 'all'
		phils = phils.select('shadows.*, names.lang, names.label').joins(:names).where('lang = ?', lang)
		if phils.length > 2
			phil_label = phils[0..1].collect{|phil| (sprintf("%04d",phil.measure_pos))+' '+(phil.show_label(lang, true)[3]) }
			phil_label = phil_label.join(', ')+' …'
		else
			phil_label = phils.collect{|phil| (sprintf("%04d",phil.measure_pos))+' '+(phil.show_label(lang, true)[3]) }
			phil_label = phil_label.join(', ')
		end
		phil_label.gsub(' ','&nbsp;')
	end

	def simple_phil_label(phils, lang)
		phils = phils.select('shadows.*, names.lang, names.label').joins(:names).where('lang = ?', lang)
		if phils.length > 2
			phil_label = phils[0..1].collect{|phil| phil.show_label(lang, true)[3] }
			phil_label = phil_label.join(', ')+' …'
		else
			phil_label = phils.collect{|phil| phil.show_label(lang, true)[3] }
			phil_label = phil_label.join(', ')
		end
	end
end
