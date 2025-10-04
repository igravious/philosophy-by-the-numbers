class WorksController < ApplicationController
  before_action :set_work, only: [:show, :edit, :update, :destroy]
	before_action :set_filters, only: [:index, :stats]

	helper_method :sort_column, :sort_direction, :sort_it
	helper_method :toggle_column, :toggle_state

	def stats
		Shadow.none
		@not_obs = Work.where.not(obsolete: true)

				works = Work.order('measure desc').group(:measure)
				work_groupings = works.count
				num_work_blocks = (work_groupings.length)-1 # zero it
	
		@top_phil = {}
		@not_obs.order(measure: :asc).each{ |work|
			score = 1+((num_work_blocks-(work.measure_pos-1)).to_f/num_work_blocks.to_f)
			phils = Philosopher.where(id: Expression.where(work_id: work.id).pluck(:creator_id))
			#phils = work.creators
			phils.each do |phil|
				e_id = phil.entity_id
				if @top_phil.key?(e_id)
					@top_phil[e_id] += score
				else
					@top_phil[e_id] = score
				end
			end
		}
		@top_phil = @top_phil.each_with_object({}){|(k,v),o|(o[v]||=[]).push(k)}.sort.reverse.to_h
	end

  # GET /works
  # GET /works.json
  def index
		Shadow.none
		#@not_obs = Work.where.not(obsolete: true)
		@not_obs = Work.all
		respond_to do |format|
			format.html do
				if params.key?(:philosopher_id) # :creator_id ???
					@creator_id = params[:philosopher_id]
					@all = @not_obs.where(id: Expression.where(creator_id: params[:philosopher_id]).pluck(:work_id)).order('measure desc')
					one_page = true
				else
					# more work to do in view
					if params.key?(:gender)
						if 'Q6581072' == params[:gender]
							@all = @not_obs.where(id: Expression.where(creator_id: Philosopher.where(gender: 'Q6581072').pluck(:id)).pluck(:work_id))
						else
							@all = @not_obs
						end
					else
						@all = @not_obs
					end
					one_page = false
				end

				if params.key?(:info)
					if params[:info].blank?
						params[:info] = 'info'
					end
					@info = params[:info]
				else
					@info = nil
				end

				@lang = params[:lang]
				if 'all' == @lang
					# more work to do in view
					@works = @all.select('shadows.*')
				else
					@works = @all.select('shadows.*, names.lang, names.label').joins(:names).where('names.lang =?', @lang)
				end
				Rails.logger.warn "@works.size : #{@works.size} for @lang : #{@lang}"

				s_c = sort_column
				s_d = sort_direction
				#Rails.logger.info "   sort_column: “#{s_c}”\nsort_direction: “#{s_d}”"
				@works = @works.order('"'+s_c+'"'+s_d)

				@page_title = '¡The Works!'

				# neat pagination pattern
				@page = params[:page]
				if one_page
					@works = @works.page(1).per(@works.size)
				else
					@works = @works.page @page
				end
				Rails.logger.warn 'warning!'
				Rails.logger.warn @works.size
			end
			format.json do
				works = @not_obs.select('shadows.*, names.lang, names.label').joins(:names).where('names.lang = ?', 'en').order(danker: :desc)
				render :json => works.pluck(:entity_id, :label)
			end
		end
  end

  # GET /works/1
  # GET /works/1.json
  def show
  end

  # GET /works/new
  def new
    @work = Work.new
  end

  # GET /works/1/edit
  def edit
		if params.key?(:philosopher_id) # :creator_id ???
			p = Philosopher.find(params[:philosopher_id])
			label = Name.where(lang: 'en', shadow_id: p.id).first.label
			@text_list = Text.where(id: Writing.where(author_id: Author.where(english_name: label)).pluck(:text_id)).collect {|k,v| [k.name_in_english,k.id]}
			Rails.logger.warn " … #{@text_list}"
		end
  end

  # POST /works
  # POST /works.json
  def create
    @work = Work.new(work_params)

    respond_to do |format|
      if @work.save
        format.html { redirect_to @work, notice: 'Work was successfully created.' }
        format.json { render action: 'show', status: :created, location: @work }
      else
        format.html { render action: 'new' }
        format.json { render json: @work.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /works/1
  # PATCH/PUT /works/1.json
  def update
    respond_to do |format|
			Rails.logger.warn work_params.inspect
			params['name_hack'] = Text.find(params['name_hack']).name_in_english
			Rails.logger.warn work_params.inspect
      if @work.update(work_params)
        format.html { redirect_to @work, notice: 'Work was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @work.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /works/1
  # DELETE /works/1.json
  def destroy
    @work.destroy
    respond_to do |format|
      format.html { redirect_to works_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_work
			Shadow.none
      @work = Work.find(params[:id])
    end

		def set_filters
			#if not params.key?(:type)
			#	params[:type] = ''
			#end
			String.include ::CoreExtensions::String::SplitPeas
			if (not params.key?(:lang)) or params[:lang].blank?
				langs = request.env['HTTP_ACCEPT_LANGUAGE'].to_s.splat(",").map do |lang| 
					l, q = lang.splat(";q=")
					[l, (q || '1').to_f]
				end
				# http://stackoverflow.com/questions/7113736/detect-browser-language-in-rails
				# Rails.logger.info langs
				ordered_langs = langs.sort_by(&:last).map(&:first).reverse
				# Rails.logger.info ordered_langs
				begin
					params[:lang] = ordered_langs[0].splat('-')[0] # TODO fix en-GB and such
				rescue
					params[:lang] = 'all' #?
				end
			end
			#if (not params.key?(:metric)) or params[:metric].blank?
			#	params[:metric] = 0
			#end
		end

    # Never trust parameters from the scary internet, only allow the white list through.
    def work_params
      params.permit(:page, :name_hack, :id)
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
			%w[asc desc].include?(params[:direction]) ? params[:direction] : Work::column_direction(sort_column)
		end

		def sort_it(column)
			Work::column_direction(column)
		end
end
