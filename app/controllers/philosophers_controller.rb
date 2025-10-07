class PhilosophersController < ApplicationController
  before_action :set_philosopher, only: [:show, :edit, :update, :destroy]
	before_action :set_filters, only: [:index, :specific, :compare]

	helper_method :sort_column, :sort_direction, :sort_it
	helper_method :toggle_column, :toggle_state

	def render_one(attr, val)
		begin
			# if 'all' == @lang
			#	  @shadows = Shadow.where(attr => val).select('shadows.*, names.lang, names.label').joins(:names)
			#	  @shadows = @shadows.page(1).per(@shadows.size)
			# else
				@shadows = Shadow.where(attr => val).select('shadows.*, names.lang, names.label').joins(:names).where('lang = ?', @lang).page
			# end
			rec = @shadows.first
			Rails.logger.info "====> #{rec.inspect}"
			@entity_qid = 'Q'+rec.entity_id.to_s
			@type = rec.type
			@metric = 0
			@label = ''
			@yearage[:normal] = {checked: true}
			@living = ''
			postamble(1, @shadows)
			render 'index'
		rescue ActiveRecord::RecordNotFound => e
			@notice = "Philosopher not found: #{e.message}"
			Rails.logger.warn @notice
			@entity_qid = ''
			postamble(0, Shadow.none)
		rescue StandardError => e
			@notice = "Error retrieving single philosopher: #{e.message}"
			Rails.logger.error @notice
			@entity_qid = ''
			postamble(0, Shadow.none)
		end
	end

	def postamble(max, selection) # just pass in ids, no?
		require 'knowledge'
		ids = selection.pluck('id')
		name_count = Name.where(shadow_id: ids).select('lang').group(:lang).order('count_lang desc, lang').count
		name_count.delete('en_match')
		if 1 == max
			lotsa_names = Philosopher.where(id: ids).select('shadows.*, names.lang, names.label').joins(:names)
			@language_list = [["– (#{name_count.size})", 'all']] # localise 'all'
			@language_list += lotsa_names.collect {|rec| (rec.lang=='en_match')?nil:["#{rec.label}@#{rec.lang}",rec.lang]}
			@language_list.delete_if{|row|row.nil?}
		else
			@language_list = [["all (#{max})", 'all']]
			@language_list += name_count.collect {|k,v| ["#{Knowledge::MediaWiki::Languages::NAMES[k]} (#{v})",k]}
			# @type_list      = selection.select('type').group(:type).order('type asc').count.collect {|k,v| ["#{k} (#{v})",k]}
			# @rel_size = Role.joins(:capacity).select('capacities.*').where('capacities.relevant = ?', true).group('roles.shadow_id').size
		end
		@meta_list = MetaFilter.all.collect {|mf| [mf.filter]}
		Rails.logger.warn @meta_list
	end

	def preamble(max, selection)
		@lang = params[:lang]
		@yearage = {}
		@gender = {} # m = Q6581097 – f = Q6581072
	end

	def remove_redirects(selection)
		dupes = P::Smart.where('entity_id <> redirect_id').pluck('redirect_id').uniq
		@all.where.not(entity_id: dupes)
	end

	def bulkage(sym)
		"&keys[]=#{sym}&values[]=#{params[sym]}"
	end

	include MetaControllerConcern

	# flash, aw haw!
	#
	# specific_philosophers GET    /philosophers/specific(.:format)                       philosophers#specific
	def specific
		params[:type] = 'Philosopher'
		Shadow.none
		return if redirect_to_meta

		respond_to do |format|
			format.html do
				@ids = params[:ids]
				begin
					if @ids && @ids.respond_to?(:size) && @ids.size == 1
						# they're Q's
						@an_id = do_one('Q'+@ids[0])
						return # already rendered
					end
				rescue NoMethodError => e
					# NoMethodError in PhilosophersController#specific
					# undefined method `size' for nil:NilClass
					Rails.logger.warn "NoMethodError in specific action: #{e.message}"
				rescue StandardError => e
					Rails.logger.error "Unexpected error in specific action: #{e.message}"
				end

				@all = Philosopher.where(entity_id: @ids)
				@all = remove_redirects(@all)
				@max = @all.size
				render_magic
			end
			format.json {}
		end
	end

	def blank_compare
		@a_less_b = Shadow.none
		@b_less_a = Shadow.none
		@shadows = Shadow.none
		preamble(0, @shadows)
		postamble(0, @shadows)
		@a_less_b = @a_less_b.page @page
		@b_less_a = @b_less_a.page @page
	end

	def compare
		params[:type] = 'Philosopher'
		if params.key?(:meta) and not params[:meta].empty?
			rec_one = MetaFilter.where(filter: params[:meta].first).first
			rec_two = MetaFilter.where(filter: params[:meta].second).first
			if rec_one.nil? or rec_two.nil?
				blank_compare
			else
				begin
					mfp_one = MetaFilterPair.find_by!(meta_filter_id: rec_one, key: 'ids')
					Rails.logger.warn mfp_one.value
					mfp_two = MetaFilterPair.find_by!(meta_filter_id: rec_two, key: 'ids')
					Rails.logger.warn mfp_two.value

					a_less_b = mfp_one.value - mfp_two.value
					@all = Philosopher.where(entity_id: a_less_b)
					@max = @all.size
					@a_less_b = magic
					@a_less_b = @a_less_b.page @page

					b_less_a = mfp_two.value - mfp_one.value
					@all = Philosopher.where(entity_id: b_less_a)
					@max = @all.size
					@b_less_a = magic
					@b_less_a = @b_less_a.page @page
				rescue ActiveRecord::RecordNotFound => e
					@notice = "Meta filter not found: #{e.message}"
					Rails.logger.warn @notice
					blank_compare
				rescue StandardError => e
					@notice = "Error during comparison: #{e.message}"
					Rails.logger.error @notice
					blank_compare
				end
			end
		else
			blank_compare
		end
	end

  # from_filter_philosophers GET    /philosophers/from_filter/:id(.:format)                philosopher#from_filter

	def from_filter
		@meta_filter = MetaFilter.find(params[:id])
		@meta = @meta_filter.filter
		@meta_filter_pairs = MetaFilterPair.where(meta_filter_id: @meta_filter)
		@meta_filter_pairs.each {|m|
			params[m.key] = m.value
		}
		set_filters # hah, funny how that worked out!
		require_relative '../../lib/app_config'
		@whereami = "#{AppConfig.get('RELATIVE_URL_ROOT', '')}/philosophers"
		if params.key?(:ids) and not params[:ids].blank?
			specific
		else
			index
		end
	end

	def do_one(uno) # why is this different to the case where the many is but one?
		preamble(1, Philosopher.where(id: uno))
		if 'Q' == uno[0]
			render_one(:entity_id, uno[1..-1].to_i)
		else
			render_one(:id, uno.to_i)
		end
		uno
	end

  # GET /philosophers
  # GET /philosophers.json
  def index
		params[:type] = 'Philosopher'
		Shadow.none
		return if redirect_to_meta

		respond_to do |format|
			format.html do
				if params.key?(:an_id) and not params[:an_id].blank?
					@an_id = do_one(params[:an_id])
					return
				end

				@all = Philosopher.all
				@all = remove_redirects(@all)
				@max = @all.size
				render_magic
			end
			format.json {}
		end
  end

	def render_magic
		magic

		render 'index'
	end

	# this is where the magic happens boys
	def magic
		Rails.logger.info "got #{@max} of 'em"
		preamble(@max, @all)
		@entity_qid = nil # in the case where one is rendered @entity_qid is set
		#Rails.logger.info "Potentially multiple items in result set"
		@page = params[:page]
		@hide = params[:hide]
		@type = params[:type]
		where_clause = ['type = ?', @type]
	
		begin	
			@metric = params[:metric].to_i
			if @metric > 0
				#@all = @all.limit(@metric)
				#where_clause[0] += ' AND metric >= ?'
				#where_clause.push(@metric)
				where_clause[0] += ' AND metric_pos <= ?'
				where_clause.push(@metric)
			end
		rescue ArgumentError => e
			Rails.logger.warn "Invalid metric parameter: #{e.message}"
		rescue StandardError => e
			Rails.logger.error "Error processing metric parameter: #{e.message}"
		end

		if params.key?(:gender)
			if 'f' == params[:gender]
				@gender[:f] = {checked: true}
				where_clause[0] += " AND gender = ?"
				where_clause.push('Q6581072')
			elsif 'm' == params[:gender]
				@gender[:m] = {checked: true}
				where_clause[0] += " AND gender = ?"
				where_clause.push('Q6581097')
			end
		end

		if params.key?(:viaf) and params[:viaf] == 'on'
			@viaf = 'checked'
			@no_viaf = ''
			where_clause[0] += ' AND viaf IS NOT NULL'
		elsif params.key?(:no_viaf) and params[:no_viaf] == 'on'
			@viaf = ''
			@no_viaf = 'checked'
			where_clause[0] += ' AND viaf IS NULL'
		else
			@viaf = ''
			@no_viaf = ''
		end
		
		if 'all' == @lang
			#@shadows = @all.select('shadows.*, names.*, MAX(names.langorder)').group('shadows.id')
			# SQLite3::SQLException: no such column: label (if @lang == 'all')
			@shadows = @all.select('shadows.*')
		else
			where_clause[0] += ' AND lang = ?'
			if @lang == 'en'
				where_clause.push('en_match')
			else
				where_clause.push(@lang)
			end
			@shadows = @all.select('shadows.*, names.lang, names.label').joins(:names)
			if params.key?(:label) and not params[:label].blank?
				@label = params[:label]
				where_clause[0] += ' AND label LIKE ?'
				where_clause.push("%#{@label}%")
			end
		end
		#Rails.logger.info @shadows
		year = Date.today.to_s.splat('-').first.to_i # cache :/
		@before = nil
		if params.key?(:before)
			params[:before] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/
			if not $~.nil?
				range = $~.to_s.to_i
				if range > -4000 and range < (year-17)
					@before = range
				end
			end
		end
		@after = nil
		if params.key?(:after)
			params[:after] =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/
			if not $~.nil?
				range = $~.to_s.to_i
				if range > -4000 and range < (year-17)
					@after = range
				end
			end
		end
		# FIXME - set more dates !! missing about 1,500 of 13,000
		if not @before.nil? and @after.nil? # interact with :yearage and :living
			@shadows = @shadows.where("birth_year < (#{@before})")
		elsif not @after.nil? and @before.nil?
			@shadows = @shadows.where("birth_year > (#{@after})")
		elsif not @before.nil? and not @after.nil?
			if @after < @before
				@shadows = @shadows.where("(birth_year > (#{@after})) AND (birth_year < (#{@before}))")
			else
				@after = nil
				@before = nil
			end
		elsif params.key?(:yearage)
			if 'full' == params[:yearage] # both dates set
				if params.key?(:living)
					params[:living] = 'off'
				end
				@yearage[:full] = {checked: true}
				@shadows = @shadows.where.not(birth_year: nil, death_year: nil)
			elsif 'empty' == params[:yearage] # 
				if params.key?(:living)
					params[:living] = 'off'
				end
				@yearage[:empty] = {checked: true}
				@shadows = @shadows.where("(birth_year IS NULL) OR (death_year IS NULL)")  # AND birth_year <= (#{year}-110))")
			else
				@yearage[:normal] = {checked: true}
			end
		else
			@yearage[:normal] = {checked: true}
		end
		if params.key?(:living) and params[:living] == 'on' # TODO :dead and :excluding_blank
			@living = 'checked'
			@shadows = @shadows.where("(death_year IS NULL) AND (birth_year > (#{year}-110))")
		else
			@living = ''
		end
		s_c = sort_column
		s_d = sort_direction
		t_c = toggle_column
		# should make sure the toggleable column is boolean

		toggle_h = {
			:borchert  => ' AND borchert = ?',
			:internet  => ' AND internet = ?',
			:cambridge => '	AND cambridge = ?',
			:kemerling => '	AND kemerling = ?',
			:populate  => '	AND populate = ?',
			:oxford    => '	AND oxford = ?',
			:routledge => '	AND routledge = ?',
			:dbpedia   => '	AND dbpedia = ?',
			:inphobool => '	AND inphobool = ?',
			:stanford  => '	AND stanford = ?'
		}
		where_not_clause = []
		if t_c.present?
			@toggle = t_c
			toggle_h.each do |key, value|
				if t_c.to_sym != key
					where_clause[0] += value
					where_clause.push(false)
				end
			end
			where_clause[0] += " AND #{t_c} = ?"
			where_clause.push(true)
		else # kinda mutually exclusive
			if params.key?(:all_ticked) and params[:all_ticked] == 'on'
				@all_ticked = 'checked'
				where_not_clause[0] = 'borchert = ? AND internet = ? AND cambridge = ? AND kemerling = ? AND populate = ? AND oxford = ? AND routledge = ? AND dbpedia =? AND stanford = ? AND inphobool = ?'
				# where_clause[0] += ' AND borchert = ? AND internet = ? AND cambridge = ? AND kemerling = ? AND populate = ? AND oxford = ? AND routledge = ? AND stanford = ? AND inphobool = ?'
				10.times{where_clause.push(true)}
			end
			if params.key?(:only_ticked) and params[:only_ticked] == 'on'
				@only_ticked = 'checked'
				where_not_clause[0] = 'borchert = ? AND internet = ? AND cambridge = ? AND kemerling = ? AND populate = ? AND oxford = ? AND routledge = ? AND dbpedia =? AND stanford = ? AND inphobool = ?'
				# where_not_clause[0] = 'borchert = ? AND internet = ? AND cambridge = ? AND kemerling = ? AND populate = ? AND oxford = ? AND routledge = ? AND stanford = ? AND inphobool = ?'
				10.times{where_not_clause.push(false)}
			end
		end
		if where_not_clause.empty?
			@shadows = @shadows.where(where_clause).order('"shadows"."'+s_c+'" '+s_d)
		else
			@shadows = @shadows.where(where_clause).where.not(where_not_clause).order('"shadows"."'+s_c+'" '+s_d)
		end
		@extent = @shadows.length
		Rails.logger.info "now got #{@extent} of 'em"
		postamble(@max, @shadows)
		
		@shadows = @shadows.page @page
	end

  # GET /shadows/1
  # GET /shadows/1.json
  def show
  end

  # GET /shadows/new
  def new
    @shadow = Shadow.new
  end

  # GET /shadows/1/edit
  def edit
  end

  # POST /shadows
  # POST /shadows.json
  def create
    @shadow = Shadow.new(shadow_params)

    respond_to do |format|
      if @shadow.save
        format.html { redirect_to @shadow, notice: 'Shadow was successfully created.' }
        format.json { render action: 'show', status: :created, location: @shadow }
      else
        format.html { render action: 'new' }
        format.json { render json: @shadow.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /shadows/1
  # PATCH/PUT /shadows/1.json
  def update
    respond_to do |format|
      if @shadow.update(shadow_params)
        format.html { redirect_to @shadow, notice: 'Shadow was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @shadow.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shadows/1
  # DELETE /shadows/1.json
  def destroy
    @shadow.destroy
    respond_to do |format|
      format.html { redirect_to shadows_url }
      format.json { head :no_content }
    end
  end

  private
		def set_filters
			if not params.key?(:type)
				params[:type] = ''
			end
			if (not params.key?(:lang)) or params[:lang].blank?
				langs = request.env['HTTP_ACCEPT_LANGUAGE'].to_s.splat(",").map do |lang| 
					l, q = lang.splat(";q=")
					[l, (q || '1').to_f]
				end
				# http://stackoverflow.com/questions/7113736/detect-browser-language-in-rails
				Rails.logger.info langs
				ordered_langs = langs.sort_by(&:last).map(&:first).reverse
				# Rails.logger.info ordered_langs
				begin
					params[:lang] = ordered_langs[0].splat('-')[0] # TODO fix en-GB and such
				rescue NoMethodError, IndexError
					params[:lang] = 'all' #?
				end
			end
			if (not params.key?(:metric)) or params[:metric].blank?
				params[:metric] = 0
			end
		end

    # Use callbacks to share common setup or constraints between actions.
    def set_philosopher
      @shadow = Shadow.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def philosopher_params
      params.require(:philosopher).permit(:type, :entity_qid, :metric, :page)
    end

		def toggle_column
				Shadow.column_names.include?(params[:toggle]) ? params[:toggle] : nil
		end

		def toggle_state
			%w[on off].include?(params[:toggle_state]) ? params[:toggle_state] : ((params.key?(:all_ticked) and params[:all_ticked].present?) ? 'off' : 'on')
		end

		def sort_column
			(
				(Shadow.column_names.include?(params[:sort])) or 
				(Name.column_names.include?(params[:sort]))
			) ? params[:sort] : 'measure'
		end
		  
		def sort_direction
			%w[asc desc].include?(params[:direction]) ? params[:direction] : Philosopher::column_direction(sort_column)
		end

		def sort_it(column)
			Philosopher::column_direction(column)
		end
end
