class ShadowsController < ApplicationController
  before_action :set_shadow, only: [:show, :edit, :update, :destroy]
	before_action :set_filters, only: [:index]

	helper_method :sort_column, :sort_direction

  # GET /shadows
  # GET /shadows.json
  def index
		Rails.logger.info "request.path is #{request.path}"
		@whereami = request.path.split(File::SEPARATOR).last
		if @whereami != 'shadows'
			case @whereami
			when "philosophers"
				if params[:type].blank?
					params[:type] = 'Philosopher'
				end
			else
				Rails.logger.warn "Unrecognised shadow path!"
			end
		end
		@all = Shadow.all
		@max = @all.length
		require 'knowledge'
		@language_list  = [["all (#{@max})", 'all']]
		@language_list += Name.select('lang').group(:lang).order('count_lang desc, lang').count.collect {|k,v| ["#{Knowledge::MediaWiki::Languages::NAMES[k]} (#{v})",k]}
		@type_list      = @all.select('type').group(:type).order('type asc').count.collect {|k,v| ["#{k} (#{v})",k]}
		@lang = params[:lang]
		@yearage = {}
		if params.key?(:entity_id) and not params[:entity_id].blank?
			begin
				if 'all' == @lang
					#@shadows = Shadow.where(entity_id: params[:entity_id]).select('shadows.*').page @page
					@shadows = Shadow.where(entity_id: params[:entity_id]).select('shadows.*').page
				else
					#@shadows = Shadow.where(entity_id: params[:entity_id]).select('shadows.*, names.lang, names.label').joins(:names).where('lang = ?', @lang).page @page
					@shadows = Shadow.where(entity_id: params[:entity_id]).select('shadows.*, names.lang, names.label').joins(:names).where('lang = ?', @lang).page
				end
				@entity_id = @shadows.first.entity_id
				@type = @shadows.first.type
				@metric = 0
				@label = ''
				@yearage[:normal] = {checked: true}
				@living = ''
				render
				return
			rescue
				Rails.logger.error "Error retrieving single shadow: #{$!}"
				@entity_id = ''
			end
		end
		
		Rails.logger.info "Potentially multiple items in result set"
		@page = params[:page]
		
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
		rescue
		end

		if params.key?(:viaf) and params[:viaf] == 'on'
			@viaf = 'checked'
			where_clause[0] += ' AND viaf IS NOT NULL'
		elsif params.key?(:no_viaf) and params[:no_viaf] == 'on'
			@no_viaf = 'checked'
			where_clause[0] += ' AND viaf IS NULL'
		else
			@viaf = ''
			@no_viaf = ''
		end
		
		if 'all' == @lang
			#@shadows = @all.select('shadows.*, names.*, MAX(names.langorder)').group('shadows.id')
			@shadows = @all.select('shadows.*')
		else
			where_clause[0] += ' AND lang = ?'
			where_clause.push(@lang)
			if params.key?(:label) and not params[:label].blank? # only when specific lang
				# sanitize?
				@label = params[:label]
				where_clause[0] += ' AND label LIKE ?'
				where_clause.push("%#{@label}%")
			end
			@shadows = @all.select('shadows.*, names.lang, names.label').joins(:names)
		end
		#Rails.logger.info @shadows
		if params.key?(:yearage)
			if 'full' == params[:yearage]
				if params.key?(:living)
					params[:living] = 'off'
				end
				@yearage[:full] = {checked: true}
				@shadows = @shadows.where.not(birth_year: nil, death_year: nil)
			elsif 'empty' == params[:yearage]
				if params.key?(:living)
					params[:living] = 'off'
				end
				@yearage[:empty] = {checked: true}
				@shadows = @shadows.where('birth_year IS NULL OR death_year IS NULL')
			else
				@yearage[:normal] = {checked: true}
			end
		else
			@yearage[:normal] = {checked: true}
		end
		if params.key?(:living) and params[:living] == 'on'
			@living = 'checked'
			year = Date.today.to_s.split('-').first.to_i
			@shadows = @shadows.where("death_year IS NULL AND (birth_year > (#{year}-110))")
		else
			@living = ''
		end
		Rails.logger.info where_clause
		@shadows = @shadows.where(where_clause).order(sort_column + " " + sort_direction)
		@extent = @shadows.length
		
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
				langs = request.env['HTTP_ACCEPT_LANGUAGE'].to_s.split(",").map do |lang| 
					l, q = lang.split(";q=")
					[l, (q || '1').to_f]
				end
				# http://stackoverflow.com/questions/7113736/detect-browser-language-in-rails
				Rails.logger.info langs
				ordered_langs = langs.sort_by(&:last).map(&:first).reverse
				Rails.logger.info ordered_langs
				params[:lang] = ordered_langs[0].split('-')[0] # TODO fix en-GB and such
			end
			if (not params.key?(:metric)) or params[:metric].blank?
				params[:metric] = 0
			end
		end

    # Use callbacks to share common setup or constraints between actions.
    def set_shadow
      @shadow = Shadow.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def shadow_params
      params.require(:shadow).permit(:type, :entity_id, :metric, :page)
    end

		def sort_column
			(Shadow.column_names.include?(params[:sort]) or Name.column_names.include?(params[:sort])) ? params[:sort] : 'entity_id'
		end
		  
		def sort_direction
			%w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
		end
end
