class CapacitiesController < ApplicationController
  before_action :set_capacity, only: [:show, :edit, :update, :destroy, :toggle, :scribble]

	helper_method :sort_column, :sort_direction, :sort_it

  # GET /capacities
  # GET /capacities.json
  def index
		if params[:filter] == 'duplicates'
			@mode = 1
			@info = 'duplicate Capacities'
			dupes = Capacity.group(:label).having("count(label)>1").size.keys
			@capacities = Capacity.where(label: dupes)
			@page_title = 'Listing Capacity Labels (with counts)'
		else
			@mode = 0
			@info = 'all Capacities'
			# pagination
    	# @capacities = Capacity.all.limit(100) # just 100!
    	@capacities = Capacity.all
			@page_title = 'Listing Capacity Labels'
		end
		@page = params[:page]
		@capacities = @capacities.page @page
  end

	def	index_count
		@capacities = Capacity.joins(:roles).select('capacities.*', "COUNT('roles.entity_id')	AS 'dynamic_count'").group('capacities.entity_id')
		s_c = sort_column
		s_d = sort_direction
		# column _MUST_ be in double-quotes!
		order = " \"#{s_c}\" #{s_d} "
		@capacities = @capacities.order(order)
	end

	def relevant
	end

  # GET /capacities/1
  # GET /capacities/1.json
  def show
  end

	def scribble
    respond_to do |format|
      if @capacity.update(capacity_params)
        format.html { redirect_to @capacity, notice: 'Capacity was successfully toggled.' }
        format.json { render :show, status: :ok, location: @capacity } # show.json.jbuilder
        format.js { render js: "console.log('capacity scribble success: #{@capacity.to_json.html_safe}')", status: :ok, location: @capacity }
        # format.js { render :scribble_success, status: :ok, location: @capacity }
      else
        format.html { render :edit }
        format.json { render json: @capacity.errors, status: :unprocessable_entity } # render json directly
        format.js { render :scribble_failure, status: :unprocessable_entity, location: @capacity }
      end
    end
	end

	def toggle
    respond_to do |format|
			@capacity.toggle_relevant
      if @capacity.save
        format.html { redirect_to @capacity, notice: 'Capacity was successfully toggled.' }
        format.json { render :show, status: :ok, location: @capacity } # show.json.jbuilder
        format.js { render js: "console.log('capacity toggle success: #{@capacity.to_json.html_safe}')", status: :ok, location: @capacity }
        # format.js { render :toggle_success, status: :ok, location: @capacity }
      else
        format.html { render :edit }
        format.json { render json: @capacity.errors, status: :unprocessable_entity } # render json directly
        format.js { render :toggle_failure, status: :unprocessable_entity, location: @capacity }
      end
    end
	end

  # GET /capacities/new
  def new
    @capacity = Capacity.new
  end

  # GET /capacities/1/edit
  def edit
  end

  # POST /capacities
  # POST /capacities.json
  def create
    @capacity = Capacity.new(capacity_params)

    respond_to do |format|
      if @capacity.save
        format.html { redirect_to @capacity, notice: 'Capacity was successfully created.' }
        format.json { render :show, status: :created, location: @capacity } # show.json.jbuilder
      else
        format.html { render :new }
        format.json { render json: @capacity.errors, status: :unprocessable_entity } # render json directly
      end
    end
  end

  # PATCH/PUT /capacities/1
  # PATCH/PUT /capacities/1.json
  def update
    respond_to do |format|
      if @capacity.update(capacity_params)
        format.html { redirect_to @capacity, notice: 'Capacity was successfully updated.' }
        format.json { render :show, status: :ok, location: @capacity }
      else
        format.html { render :edit }
        format.json { render json: @capacity.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /capacities/1
  # DELETE /capacities/1.json
  def destroy
    @capacity.destroy
    respond_to do |format|
      format.html { redirect_to capacities_url, notice: 'Capacity was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_capacity
      @capacity = Capacity.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def capacity_params
			params.require(:capacity).permit(:relevant, :label) # don't see a scenario when you'd need to change entity_id
    end

		def sort_column
			# default to dynamic_count
			Capacity.column_names.include?(params[:sort]) ? params[:sort] : 'dynamic_count'
		end
		  
		def sort_direction
			%w[asc desc].include?(params[:direction]) ? params[:direction] : Capacity::column_direction(sort_column)
		end

		def sort_it(column)
			Capacity::column_direction(column)
		end
end
