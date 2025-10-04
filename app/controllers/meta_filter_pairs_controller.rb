class MetaFilterPairsController < ApplicationController
  before_action :set_meta_filter_pair, only: [:show, :edit, :update, :destroy]

  # GET /meta_filter_pairs
  # GET /meta_filter_pairs.json
  def index
		@meta_filter_pairs = MetaFilterPair.all

		@page_title = 'Listing Meta Filter Pairs'
	end

  # GET /meta_filter_pairs/1
  # GET /meta_filter_pairs/1.json
  def show
  end

  # GET /meta_filter_pairs/new
  def new
    @meta_filter_pair = MetaFilterPair.new
  end

  # GET /meta_filter_pairs/1/edit
  def edit
  end

  # POST /meta_filter_pairs
  # POST /meta_filter_pairs.json
  def create
    @meta_filter_pair = MetaFilterPair.new(meta_filter_pair_params)

    respond_to do |format|
      if @meta_filter_pair.save
        format.html { redirect_to @meta_filter_pair, notice: 'Meta filter pair was successfully created.' }
        format.json { render :show, status: :created, location: @meta_filter_pair }
      else
        format.html { render :new }
        format.json { render json: @meta_filter_pair.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /meta_filter_pairs/1
  # PATCH/PUT /meta_filter_pairs/1.json
  def update
    respond_to do |format|
      if @meta_filter_pair.update(meta_filter_pair_params)
        format.html { redirect_to @meta_filter_pair, notice: 'Meta filter pair was successfully updated.' }
        format.json { render :show, status: :ok, location: @meta_filter_pair }
      else
        format.html { render :edit }
        format.json { render json: @meta_filter_pair.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /meta_filter_pairs/1
  # DELETE /meta_filter_pairs/1.json
  def destroy
    @meta_filter_pair.destroy
    respond_to do |format|
      format.html { redirect_to meta_filter_pairs_url, notice: 'Meta filter pair was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_meta_filter_pair
      @meta_filter_pair = MetaFilterPair.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def meta_filter_pair_params
      params.require(:meta_filter_pair).permit(:meta_filter_id, :key, :value)
    end
end
