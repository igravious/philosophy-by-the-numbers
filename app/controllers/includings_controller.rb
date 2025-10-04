class IncludingsController < ApplicationController
  before_action :set_including, only: [:show, :edit, :update, :destroy]

  # GET /includings
  # GET /includings.json
  def index
    @includings = Including.all
  end

  # GET /includings/1
  # GET /includings/1.json
  def show
  end

  # GET /includings/new
  def new
    @including = Including.new
  end

  # GET /includings/1/edit
  def edit
  end

  # POST /includings
  # POST /includings.json
  def create
    @including = Including.new(including_params)

    respond_to do |format|
      if @including.save
        format.html { redirect_to @including, notice: 'Including was successfully created.' }
        format.json { render action: 'show', status: :created, location: @including }
      else
        format.html { render action: 'new' }
        format.json { render json: @including.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /includings
  # DELETE /includings.json
  def uncreate
		Rails.logger.info including_params
    @including = Including.where(including_params).first

    @including.destroy # why not a bool?
    respond_to do |format|
      format.html { redirect_to includings_url }
      format.json { head :no_content }
    end
  end

  # PATCH/PUT /includings/1
  # PATCH/PUT /includings/1.json
  def update
    respond_to do |format|
      if @including.update(including_params)
        format.html { redirect_to @including, notice: 'Including was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @including.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /includings/1
  # DELETE /includings/1.json
  def destroy
    @including.destroy
    respond_to do |format|
      format.html { redirect_to includings_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_including
      @including = Including.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def including_params
      params.require(:including).permit(:filter_id, :text_id)
    end
end
