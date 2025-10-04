class Bulk::MetaFilterPairsController < ApplicationController
  # before_action :set_meta_filter_pair, only: [:show, :edit, :update, :destroy]
  before_action :set_meta_filter, only: [:show, :edit, :update, :destroy]
  before_action :new_from_pairs, only: [:new, :create]

	# hmm, what to do for #index ?
	#
  # GET /meta_filter_pairs
  # GET /meta_filter_pairs.json
  def index
		@meta_filter_pairs = MetaFilterPair.all
	end

	# #show, #edit, #update, #destroy

  # GET /meta_filter_pairs/1
  # GET /meta_filter_pairs/1.json
  def show
  end

  # GET /meta_filter_pairs/1/edit
  def edit
  end

  # PATCH/PUT /meta_filter_pairs/1
  # PATCH/PUT /meta_filter_pairs/1.json
  def update
		# @meta_filter_pair.update(meta_filter_pair_params)

		was_updated = false
		ActiveRecord::Base.transaction do # “Exceptions will force a ROLLBACK that returns the database to the state before the transaction began.”
			# @meta_filter.save!
			@meta_filter_pairs.each do |m|
				m.save!
			end
			was_updated = true
		end

    respond_to do |format|
      if was_updated
        format.html { redirect_to bulk_meta_filter_pair_url(@meta_filter.id), notice: 'Meta filter (and its pairs) were successfully updated.' }
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

	# #new, #create

  # GET /bulk/meta_filter_pairs/new
  def new # new from given pairs
    # @meta_filter_pair = MetaFilterPair.new
  end

  # POST /meta_filter_pairs
  # POST /meta_filter_pairs.json
  def create
    # @meta_filter_pair = MetaFilterPair.new(meta_filter_pair_params)

		was_saved = false
		ActiveRecord::Base.transaction do # “Exceptions will force a ROLLBACK that returns the database to the state before the transaction began.”
			@meta_filter.save!
			@meta_filter_pairs.each do |m|
				m.save!
			end
			was_saved = true
		end

    # was_saved = @meta_filter_pair.save

    respond_to do |format|
      if was_saved
        format.html { redirect_to bulk_meta_filter_pair_url(@meta_filter.id), notice: 'Meta filter (and its pairs) were successfully created.' }
        # format.json { render :show, status: :created, location: @meta_filter_pair }
      else
        format.html { render :new }
        # format.json { render json: @meta_filter_pair.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
		def new_from_pairs
			if params.key?(:multiplex) and not params[:multiplex].blank?
				@meta_filter = QuestionMetaFilter.new
			else
				@meta_filter = MainMetaFilter.new
			end
			@meta_filter.filter = params[:meta].first # :(
			# TODO use params.require().permit
			params.delete :meta
			params.delete :controller
			params.delete :action
			params.delete :utf8
			params.delete :authenticity_token
			params.delete :commit
			params.delete :_method
			@meta_filter_pairs = []
			params.each_pair do |k,v|
				m = MetaFilterPair.new
				m.meta_filter = @meta_filter # pity this doesn't work until there's a record backing it, huh actually it does?
				m.key = k
				m.value = v
				@meta_filter_pairs.push(m)
			end

			Rails.logger.warn '@meta_filter'
			Rails.logger.warn @meta_filter.inspect
			Rails.logger.warn '@meta_filter_pairs'
			Rails.logger.warn @meta_filter_pairs
		end

		def set_meta_filter
			@meta_filter = MetaFilter.find(params[:id])
			@meta_filter_pairs = MetaFilterPair.where(meta_filter_id: @meta_filter)
			@meta_filter_pairs.each{|m|
				unless params[m.key].nil? # then
					if m.value != params[m.key]
						m.value = params[m.key]
					end
				end
			}
			if params[:extra_ids].is_a?(Array)
				@meta_filter_pairs.each{|m|
					if 'ids' == m.key
						if '+' == params[:op]
							m.value = m.value + params[:extra_ids]
						elsif '-' == params[:op]
							m.value = m.value - params[:extra_ids]
						end
					end
				}
			end
		end

    # def set_meta_filter_pair
    #   @meta_filter_pair = MetaFilterPair.find(params[:id])
    # end

    # Never trust parameters from the scary internet, only allow the white list through.
		# TODO (re)use this strategy
    def meta_filter_pair_params
      params.require(:meta_filter_pair).permit(:meta_filter_id, :key, :value)
    end
end
