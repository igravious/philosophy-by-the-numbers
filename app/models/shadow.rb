
class Shadow < ActiveRecord::Base
  has_many :names, dependent: :destroy
  accepts_nested_attributes_for :names
  include DateTimeMethods

  def get_year(date_sym)
    year(date_sym)
  end

	def do_q(the_sym)
	end

	def year(date_sym)
		begin
			approx = (date_sym.to_s+'_approx').to_sym
			value = date_attribute(date_sym)
			if value.blank?
				nil
			elsif date_attribute(approx)
				value.to_i
			else
				boom = value.split(';')
				DateTimeMethods.extract_year(boom[0])
			end
		rescue ArgumentError, TypeError, NoMethodError
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
		rescue NoMethodError
			Rails.logger.warn "Philosopher.find(#{self.id}) needs an English label"
			en_label = "…"
		end
		[w_label, w_lang, en_label, label]
	end

	def self.column_direction(col)
		%w[entity_id label].include?(col) ? 'asc' : 'desc'
	end

	private

	def date_attribute(name)
		return self[name] if has_attribute?(name)
		metadata = attrs if respond_to?(:attrs)
		metadata[name] if metadata && metadata.has_attribute?(name)
	end
end

# class Philosopher < Shadow; end

# https://medium.com/@jbmilgrom/active-record-many-to-many-self-join-table-e0992c27c1e

class Philosopher < Shadow
		has_one :attrs, class_name: 'PhilosopherAttrs', foreign_key: :shadow_id,
						autosave: true, dependent: :destroy
		has_one :obsolete_data, -> { where(shadow_type: 'Philosopher') },
						class_name: 'ObsoleteAttrs', foreign_key: :shadow_id

		accepts_nested_attributes_for :attrs

		# List of attributes that should be delegated to attrs
		DELEGATED_ATTRIBUTES = %w[
			birth birth_approx birth_year death death_approx death_year
			floruit period dbpedia oxford2 oxford3 stanford internet
			kemerling runes populate inpho inphobool gender philosopher
		]

		delegate :birth, :birth=,
						 :birth_approx, :birth_approx=,
						 :birth_year, :birth_year=,
						 :death, :death=,
						 :death_approx, :death_approx=,
						 :death_year, :death_year=,
						 :floruit, :floruit=,
						 :period, :period=,
						 :dbpedia, :dbpedia=,
						 :oxford2, :oxford2=,
						 :oxford3, :oxford3=,
						 :stanford, :stanford=,
						 :internet, :internet=,
						 :kemerling, :kemerling=,
						 :runes, :runes=,
						 :populate, :populate=,
						 :inpho, :inpho=,
						 :inphobool, :inphobool=,
						 :gender, :gender=,
						 :philosopher, :philosopher=,
						 to: :attrs_with_autobuild

		# Ensure attrs record is created with the philosopher
		after_initialize :build_attrs_if_needed

		# Override initialize to handle mass assignment of delegated attributes
		def initialize(attributes = nil, options = {})
			# Extract delegated attributes from the hash
			delegated_attrs = {}
			if attributes.is_a?(Hash)
				DELEGATED_ATTRIBUTES.each do |attr|
					attr_sym = attr.to_sym
					if attributes.key?(attr_sym)
						delegated_attrs[attr_sym] = attributes.delete(attr_sym)
					elsif attributes.key?(attr)
						delegated_attrs[attr_sym] = attributes.delete(attr)
					end
				end
			end

			# Call parent initialize with remaining attributes
			super(attributes, options)

			# Now set the delegated attributes through delegation
			delegated_attrs.each do |key, value|
				self.send("#{key}=", value)
			end
		end

		has_many :metric_snapshots, -> { where(shadow_type: 'Philosopher') }, foreign_key: :shadow_id
		# source: :work matches with the belongs_to :work in the Expression join model
		has_many :creations, through: :route_a, source: :work  # Mirrors Work's :creators association
		# route_a "names" the X join model for accessing through the work association
		has_many :route_a, foreign_key: :creator_id, class_name: "Expression"
		has_many :works, through: :route_a, source: :work  # Alias for creations

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
	
	def reference_work_flags_json
		{
			runes: self.runes || false,
			inphobool: self.inphobool || false,
			borchert: self.borchert || false,
			internet: self.internet || false,
			cambridge: self.cambridge || false,
			kemerling: self.kemerling || false,
			populate: self.populate || false,
			oxford2: self.oxford2 || false,
			oxford3: self.oxford3 || false,
			routledge: self.routledge || false,
			dbpedia: self.dbpedia || false,
			stanford: self.stanford || false
		}.to_json
	end

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
	
	def calculate_canonicity_measure(algorithm_version: '2.1', danker_info: {})
		max_mention = (Philosopher.order('mention desc').first&.mention || 1.0) * 1.0
		ranked = Philosopher.where.not(danker: nil)
		max_rank = Philosopher.order('danker desc').first&.danker || 1.0
		min_rank = (ranked.order('danker asc').first&.danker || 0.1) / 2.0
		weights = CanonicityWeights.weights_for_version(algorithm_version)
		sources = Canonicity::Philosopher::V2::SOURCES.each_with_object({}) do |source, result|
			result[source.to_sym] = self.send(source.to_sym)
		end
		inputs = {
			mention: self.mention,
			danker: self.danker,
			capacities: self.capacities.pluck(:entity_id),
			sources: sources
		}
		result = Canonicity::Philosopher::V2.call(
			inputs: inputs,
			weights: weights,
			normalization_context: {max_mention: max_mention, max_rank: max_rank, min_rank: min_rank}
		)

		result[:normalized_measure]
	end

	def self.phil_null
		self.where('philosophy IS NULL AND philosopher IS NULL')
	end

	def self.nuke_all_date_hack
		self.where.not(date_hack: nil).update_all(date_hack: nil)
	end

	def self.repo # I M I C K W O R D S (now O O)
		self.where(inphobool: false, borchert: false, internet: false, cambridge: false, kemerling: false, populate: false, oxford2: false, oxford3: false, routledge: false, dbpedia: false, stanford: false)
	end

	private

	def attrs_with_autobuild
		# Always ensure attrs exists before delegating
		build_attrs if attrs.nil?
		attrs
	end

	def build_attrs_if_needed
		build_attrs if new_record? && attrs.nil?
	end

end

class Work < Shadow
	has_one :attrs, class_name: 'WorkAttrs', foreign_key: :shadow_id,
					autosave: true, dependent: :destroy
	has_one :obsolete_data, -> { where(shadow_type: 'Work') },
					class_name: 'ObsoleteAttrs', foreign_key: :shadow_id

	# List of attributes that should be delegated to attrs
	DELEGATED_ATTRIBUTES = %w[
		pub pub_year pub_approx work_lang copyright genre obsolete
		philrecord philtopic britannica image philosophical
	]

	delegate :pub, :pub=,
					 :pub_year, :pub_year=,
					 :pub_approx, :pub_approx=,
					 :work_lang, :work_lang=,
					 :copyright, :copyright=,
					 :genre, :genre=,
					 :obsolete, :obsolete=,
					 :philrecord, :philrecord=,
					 :philtopic, :philtopic=,
					 :britannica, :britannica=,
					 :image, :image=,
					 :philosophical, :philosophical=,
					 to: :attrs_with_autobuild

	# Ensure attrs record is created with the work
	after_initialize :build_attrs_if_needed

	# Override initialize to handle mass assignment of delegated attributes
	def initialize(attributes = nil, options = {})
		# Extract delegated attributes from the hash
		delegated_attrs = {}
		if attributes.is_a?(Hash)
			DELEGATED_ATTRIBUTES.each do |attr|
				attr_sym = attr.to_sym
				if attributes.key?(attr_sym)
					delegated_attrs[attr_sym] = attributes.delete(attr_sym)
				elsif attributes.key?(attr)
					delegated_attrs[attr_sym] = attributes.delete(attr)
				end
			end
		end

		# Call parent initialize with remaining attributes
		super(attributes, options)

		# Now set the delegated attributes through delegation
		delegated_attrs.each do |key, value|
			self.send("#{key}=", value)
		end
	end

	has_many :metric_snapshots, -> { where(shadow_type: 'Work') }, foreign_key: :shadow_id
	# `source: :creator' matches with the belongs_to :creator in the Expression join model
	has_many :creators, through: :route_b, source: :philosopher
	# `route_b' "names" the X join model for accessing throught the work association
	has_many :route_b, foreign_key: :work_id, class_name: "Expression"

	def reference_work_flags_json
		{
			borchert: self.borchert || false,
			cambridge: self.cambridge || false,
			routledge: self.routledge || false,
			philrecord: self.philrecord || false,
			philtopic: self.philtopic || false
		}.to_json
	end

	def join_attribute
		{work_id: self.id}
	end

	def calculate_canonicity_measure(algorithm_version: '2.0-work', danker_info: {})
		max_mention = (Work.order('mention desc').first&.mention || 1.0) * 1.0
		ranked = Work.where.not(danker: 0.0)
		max_rank = Work.order('danker desc').first&.danker || 1.0
		min_rank = (ranked.order('danker asc').first&.danker || 0.1) / 2.0
		weights = CanonicityWeights.weights_for_version(algorithm_version)
		phils = Philosopher.where(id: Expression.where(work_id: self.id).pluck(:creator_id))
		inputs = {
			mention: self.mention,
			danker: self.danker,
			borchert: self.borchert,
			cambridge: self.cambridge,
			routledge: self.routledge,
			philrecord: self.philrecord,
			philtopic: self.philtopic,
			genre: self.genre
		}
		result = Canonicity::Work::V2.call(
			inputs: inputs,
			weights: weights,
			normalization_context: {max_mention: max_mention, max_rank: max_rank, min_rank: min_rank},
			dependency_inputs: {author_measures: phils.collect { |phil| phil.measure }}
		)

		result[:normalized_measure]
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

	private

	def attrs_with_autobuild
		# Always ensure attrs exists before delegating
		build_attrs if attrs.nil?
		attrs
	end

	def build_attrs_if_needed
		build_attrs if new_record? && attrs.nil?
	end
end
