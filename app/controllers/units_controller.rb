class UnitsController < ApplicationController
  before_action :set_unit, only: [:show, :edit, :update, :destroy]

  # GET /units
  # GET /units.json
  def index
		@page_title = 'Listing Units for All Dictionaries'

    @units = Unit.all
		@page = params[:page]
		@units = @units.page @page unless @units.nil?
  end

	def by_dictionary
		Rails.logger.info params
		@units = Unit.where(dictionary_id: params['id'])

		# @page_title = 'Listing Units for '+link_to Dictionary.find(params['id']).title, dictionary_path(params['id'])
		@page_title = 'Listing Units for '+Dictionary.find(params['id']).title
		@page = params[:page]
		@units = @units.page @page unless @units.nil?
		render :index
	end

	def what
		Rails.logger.info params
		@units = Unit.where(dictionary_id: params['id']).where.not(what_it_is: nil)

		@page_title = 'Listing Units for '+Dictionary.find(params['id']).title
		@page = params[:page]
		@units = @units.page @page unless @units.nil?
		render :index
	end

  # GET /units/1
  # GET /units/1.json
  def show
  end

  # GET /units/new
  def new
    @unit = Unit.new
  end

  # GET /units/1/edit
  def edit
  end

  # POST /units
  # POST /units.json
  def create
    @unit = Unit.new(unit_params)

    respond_to do |format|
      if @unit.save
        format.html { redirect_to @unit, notice: 'Unit was successfully created.' }
        format.json { render action: 'show', status: :created, location: @unit }
      else
        format.html { render action: 'new' }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /units/1
  # PATCH/PUT /units/1.json
  def update
    respond_to do |format|
      if @unit.update(unit_params)
        format.html { redirect_to @unit, notice: 'Unit was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /units/1
  # DELETE /units/1.json
  def destroy
    @unit.destroy
    respond_to do |format|
      format.html { redirect_to units_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit
      @unit = Unit.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unit_params
      params.require(:unit).permit(:dictionary_id, :entry)
    end
end
