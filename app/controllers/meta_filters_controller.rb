class MetaFiltersController < ApplicationController
  before_action :set_meta_filter, only: [:show, :edit, :update, :destroy]

  # GET /meta_filters
  # GET /meta_filters.json
  def index
    @meta_filters = MetaFilter.all

		@page_title = 'Listing Meta Filters'
  end

  # GET /meta_filters/1
  # GET /meta_filters/1.json
  def show
  end

  # GET /meta_filters/new
  def new
    @meta_filter = MetaFilter.new
  end

  # GET /meta_filters/1/edit
  def edit
  end

  # POST /meta_filters
  # POST /meta_filters.json
  def create
    @meta_filter = MetaFilter.new(meta_filter_params)

    respond_to do |format|
      if @meta_filter.save
        format.html { redirect_to @meta_filter, notice: 'Meta filter was successfully created.' }
        format.json { render :show, status: :created, location: @meta_filter }
      else
        format.html { render :new }
        format.json { render json: @meta_filter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /meta_filters/1
  # PATCH/PUT /meta_filters/1.json
  def update
    respond_to do |format|
      if @meta_filter.update(meta_filter_params)
        format.html { redirect_to @meta_filter.becomes(MetaFilter), notice: 'Meta filter was successfully updated.' }
        format.json { render :show, status: :ok, location: @meta_filter }
      else
        format.html { render :edit }
        format.json { render json: @meta_filter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /meta_filters/1
  # DELETE /meta_filters/1.json
  def destroy
		to_go = MetaFilterPair.where(meta_filter_id: @meta_filter)
		we_did_it = false
		ActiveRecord::Base.transaction do
			set_length = to_go.size
			raise ActiveRecord::Rollback if set_length != to_go.delete_all
    	gone_bye_bye = @meta_filter.destroy
			raise ActiveRecord::Rollback unless gone_bye_bye
			we_did_it = true
		end
    respond_to do |format|
			if we_did_it
				format.html { redirect_to meta_filters_url, notice: 'Meta filter was successfully destroyed.' }
				format.json { head :no_content }
			else
				format.html { redirect_to meta_filters_url, notice: 'Well, that was disappointing.' }
				format.json { head :no_content }
			end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_meta_filter
      @meta_filter = MetaFilter.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def meta_filter_params
      params.require(:meta_filter).permit(:filter, :type, :key, :value)
    end
end
