class P::SmartsController < ApplicationController
  before_action :set_p_smart, only: [:show, :edit, :update, :destroy]

  # GET /p/smarts
  # GET /p/smarts.json
  def index
    @p_smarts = P::Smart.all
  end

  # GET /p/smarts/1
  # GET /p/smarts/1.json
  def show
  end

  # GET /p/smarts/new
  def new
    @p_smart = P::Smart.new
  end

  # GET /p/smarts/1/edit
  def edit
  end

  # POST /p/smarts
  # POST /p/smarts.json
  def create
    @p_smart = P::Smart.new(p_smart_params)

    respond_to do |format|
      if @p_smart.save
        format.html { redirect_to @p_smart, notice: 'Smart was successfully created.' }
        format.json { render :show, status: :created, location: @p_smart }
      else
        format.html { render :new }
        format.json { render json: @p_smart.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /p/smarts/1
  # PATCH/PUT /p/smarts/1.json
  def update
    respond_to do |format|
      if @p_smart.update(p_smart_params)
        format.html { redirect_to @p_smart, notice: 'Smart was successfully updated.' }
        format.json { render :show, status: :ok, location: @p_smart }
      else
        format.html { render :edit }
        format.json { render json: @p_smart.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /p/smarts/1
  # DELETE /p/smarts/1.json
  def destroy
    @p_smart.destroy
    respond_to do |format|
      format.html { redirect_to p_smarts_url, notice: 'Smart was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_p_smart
      @p_smart = P::Smart.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def p_smart_params
      params.require(:p_smart).permit(:entity_id, :redirect_id, :object_id, :type)
    end
end
