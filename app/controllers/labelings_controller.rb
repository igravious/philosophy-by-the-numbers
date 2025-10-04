class LabelingsController < ApplicationController
  before_action :set_labeling, only: [:show, :edit, :update, :destroy]

  # GET /labelings
  # GET /labelings.json
  def index
		@page_title = 'Listing Labelings'

    @labelings = Labeling.all
		# see compress_array.rb
  end

  # GET /labelings/1
  # GET /labelings/1.json
  def show
  end

  # GET /labelings/new
  def new
    @labeling = Labeling.new
  end

  # GET /labelings/1/edit
  def edit
  end

  # POST /labelings
  # POST /labelings.json
  def create
    @labeling = Labeling.new(labeling_params)

    respond_to do |format|
      if @labeling.save
        format.html { redirect_to @labeling, notice: 'Labeling was successfully created.' }
        format.json { render action: 'show', status: :created, location: @labeling }
      else
        format.html { render action: 'new' }
        format.json { render json: @labeling.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /labelings/1
  # PATCH/PUT /labelings/1.json
  def update
    respond_to do |format|
      if @labeling.update(labeling_params)
        format.html { redirect_to @labeling, notice: 'Labeling was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @labeling.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /labelings/1
  # DELETE /labelings/1.json
  def destroy
    @labeling.destroy
    respond_to do |format|
      format.html { redirect_to labelings_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_labeling
      @labeling = Labeling.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def labeling_params
      params.require(:labeling).permit(:tag_id, :text_id)
    end
end
