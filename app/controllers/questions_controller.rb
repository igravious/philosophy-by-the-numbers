class QuestionsController < ApplicationController

	# settings page, cookies n such
	RECORDS_PER_PAGE = 40

	# 2.4.0 :001 > Property.all.pluck(:property_id).uniq
	#    (136.8ms)  SELECT "properties"."property_id" FROM "properties"
	#  => [27, 737, 1412, 19, 20]

	def setup
		@property_names = {
			# places
			27 => 'country of citizenship',
			19 => 'place of birth',
			20 => 'place of death',
			# inf
			737 => 'influenced by',
			# lang
			1412 => 'languages spoken, written or signed',
			# other
			802 => 'student',
			1559 => 'name in native language'
		}
	end

	### IRISH

	def dumb_irish
		setup
		@grouping = 'Irish'

		@property_list = Property.where('data_label = "Ireland" OR data_label = "Northern Ireland" OR data_label = "Kingdom of Ireland"')
		#@property_list = Property.where('data_label LIKE "%Ireland%"')

		@entity_ids = @property_list.pluck(:entity_id).uniq

		render "index"
	end

	def irish
		setup
		@grouping = 'Irish'

		@property_list = P::Smart.where(type: ['P::P19', 'P::P20', 'P::P27'])
		@property_list = @property_list.henry
		#@property_list = @property_list.where('entity_id = redirect_id')
		@property_list = @property_list.where('object_label = "Ireland" OR object_label = "Northern Ireland" OR object_label = "Kingdom of Ireland"')
		#@property_list = Property.where('data_label LIKE "%Ireland%"')

		@entity_ids = @property_list.pluck(:entity_id).uniq
		@instance_ids    = P::P31.pluck(:entity_id, :object_label).to_h

		render "index"
	end

	### UPLOAD
	
	def upload

		@box = ''
		@entity_ids = []
		
	end

	def uploaded
		file = params[:filename]

		begin
			@box = file.read.strip
			@entity_ids = []
		rescue

			list = params[:fileText].lines

			String.include ::CoreExtensions::String::SplitPeas
			# compress all whitespace to one unit
			@entity_ids = list.collect{|line| line.gsub(/\s+/m, ' ').strip.splat(' ')[0][1..-1]}

			@box = ':)'
		end

		render 'upload'
	end

	### THINKERS

	def dumb_thinkers
		setup
		@grouping = params[:connection]

		@property_list = Property.where("data_id = #{params[:data_id]}")

		@entity_ids = @property_list.pluck(:entity_id).uniq

		render "index"
	end

	def thinkers
		setup
		@grouping = params[:connection]

		@property_list = Property.where("data_id = #{params[:data_id]}")

		@entity_ids = @property_list.pluck(:entity_id).uniq

		render "index"
	end

	### COUNTRIES

	def dumb_countries
		@feature = 'countries'

		@feature_list = Property.where(property_id: 27).group(:data_label).count(:data_label).sort_by {|_key, value| value}.reverse
		# @feature_ids  = Property.where(property_id: [27]).distinct.pluck(:data_label, :data_id).to_h
		@feature_ids  = Property.where(property_id: [27]).pluck(:data_label, :data_id).to_h

		@page_title = 'Countries'
		render "table"
	end

	def countries
		generic_features('country', ['P::P27'])
	end

	def all_countries
		generic_features('every country', ['P::J27'])
	end

	### SCHOOLS
	
	def schools(ids=nil)
		generic_features('school', ['P::D1'], ids)
	end

	### INTERESTS
	
	def interests(ids=nil)
		generic_features('interest', ['P::D2'], ids)
	end

	### SUBJECTS
	
	def subjects(ids=nil)
		generic_features('subject', ['P::D3'], ids)
	end

	### PLACES OF BIRTH

	def birth_places
		generic_features('country', ['P::P19'])
	end

	### PLACES OF DEATH

	def death_places
		generic_features('country', ['P::P20'])
	end

	### INSTANCES

	def instances
		@feature = 'instances'

		@feature_list    = P::Smart.where(type: 'P::P31').henry # :(
		@feature_labels  = @feature_list.pluck(:object_id, :object_label).to_h
		@feature_list    = @feature_list.group(:object_id).count(:object_id).sort_by {|_key, value| value}.reverse

		@page_title = 'Instances'
		render "table"
	end

	### LANGUAGES

	def dumb_languages
		@feature = 'languages'

		@feature_list  = Property.where(property_id: [1412])
		if params.has_key?(:label)
			@label = params[:label]
			@feature_list = @feature_list.where("data_label LIKE '%#{@label}%'")
		end
		@feature_list = @feature_list.group(:data_label).count(:data_label).sort_by {|_key, value| value}.reverse
		@feature_ids  = Property.where(property_id: [1412]).pluck(:data_label, :data_id).to_h

		@page_title = 'Languages'
		render "table"
	end

	def languages
		generic_features('language', ['P::P1412'])
	end

	### PLACES

	def places
		generic_features('place', ['P::P19', 'P::P20', 'P::P27'])
	end

	def all_places
		generic_features('every place', ['P::P19', 'P::P20', 'P::J27'])
	end

	### SPECIFIC

	def specific(discard=nil)
		Rails.logger.warn 'discard param in specific'
		Rails.logger.warn discard.inspect
		@multiplex = params[:multiplex]
		ids = params[:ids]
		send(@multiplex, ids)
	end
	
	### FROM FILTER

	def from_filter
		@meta_filter = MetaFilter.find(params[:id])
		@meta = @meta_filter.filter
		@meta_filter_pairs = MetaFilterPair.where(meta_filter_id: @meta_filter)
		@meta_filter_pairs.each {|m|
			params[m.key] = m.value
		}
		# TODO the following is all deeply troubling
		@multiplex = params[:multiplex]
		# Rails.logger.warn request.path
		require_relative '../../lib/app_config'
		@whereami = "#{AppConfig.get('RELATIVE_URL_ROOT', '')}/questions/#{@multiplex}" # ? :/
		params.delete(:multiplex)
		# this is not from a param, it's from the db (marshalled)
		String.include ::CoreExtensions::String::SplitPeas
		@features = params[:features].collect(&:to_i) # {|id| id.to_i} # .first.splat(' ').collect{|id| id.to_i}
		params.delete(:features)
		send(@multiplex)
	end

	### INFLUENCES

	def influences
		@feature = 'influences'

		@feature_list = Property.where(property_id: 737).group(:data_label).count(:data_label).sort_by {|_key, value| value}.reverse
		@feature_ids  = Property.where(property_id: [737]).distinct.pluck(:data_label, :data_id).to_h

		@page_title = 'Influences'
	end

	### AMALGAM

	def specific_features(type_str, feature_list, features)
		setup
		@grouping = 'Specific '+(type_str.capitalize)

		Rails.logger.info features

		object = 'object_id = "'+features.first+'"'
		if features.length > 1
			features[1..-1].each { |feature| # from the 2nd one until the last one do this
				object += ' OR object_id = "'+feature+'"'
			}
		end
		@property_list = feature_list.where(object)
		@property_list = @property_list.page(@page).per(RECORDS_PER_PAGE)

		@entity_ids = @property_list.pluck(:entity_id).uniq

		render "index"
	end

	def ordinary_features(type_str, feature_list)
		@feature = type_str.pluralize
		@feature_list   = feature_list

		if params.has_key?(:label)
			@label        = params[:label]
			@feature_list = @feature_list.where("object_label LIKE '%#{@label}%'")
		end
		# 2.4.0 :001 > P::J27.group(:object_id).pluck(:object_id, :object_label).size
		#    (101.2ms)  SELECT "p_smarts"."object_id", "p_smarts"."object_label" FROM "p_smarts" WHERE "p_smarts"."type" IN ('P::J27') GROUP BY "p_smarts"."object_id"
		#  => 452 
		# 2.4.0 :002 > P::J27.pluck(:object_id, :object_label).size
		#    (104.8ms)  SELECT "p_smarts"."object_id", "p_smarts"."object_label" FROM "p_smarts" WHERE "p_smarts"."type" IN ('P::J27')
		#  => 26841
		@group_list     = @feature_list.group(:object_id)
		@feature_labels = @group_list.pluck(:object_id, :object_label).to_h
		@feature_list   = @group_list.count(:object_id).sort_by {|_key, value| value}.reverse
		# @feature_list = @feature_list.page @page
		@feature_list   = Kaminari.paginate_array(@feature_list).page(@page).per(RECORDS_PER_PAGE)

		@page_title     = @feature.capitalize
		render "table"
	end

	include MetaControllerConcern

	def generic_features(type_str, type_arr, ids=nil)
		# https://stackoverflow.com/questions/1244921/rails-controller-action-name-to-string
		params[:multiplex] = action_name
		return if redirect_to_meta
		Rails.logger.warn 'generic'

		@meta_list = QuestionMetaFilter.all.collect{|qmf|[qmf.filter]}
		@page = params[:page]
		feature_list = P::Smart.where(type: type_arr) # .henry # :(
		Rails.logger.warn 'ids'
		Rails.logger.warn ids
		feature_list = feature_list.where(entity_id: ids) unless ids.nil?
		if params.has_key?(:features)
			features = params[:features] # .first.split(' ') # these are ids no, not labels :/
			# features = features.each { |feature|
			# 	feature.gsub! /_/, ' '
			# }
			if features.empty?
				ordinary_features(type_str, feature_list)
			else
				specific_features(type_str, feature_list, features)
			end
		else
			ordinary_features(type_str, feature_list)
		end
	end

end
