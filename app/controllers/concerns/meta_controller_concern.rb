# app/controllers/concerns/meta_controller_concern.rb
module MetaControllerConcern
  extend ActiveSupport::Concern

  included do
    helper_method :redirect_to_meta
  end

	def redirect_to_meta
		Rails.logger.warn '(0: redirect_to_meta)'
		if params.key?(:meta) and not params[:meta].first.empty?
		Rails.logger.warn '(1)'
			# s = "?filter=#{params[:meta]}"
			# s+= bulkage(:direction)
			# s+= bulkage(:sort)
			# redirect_to controller: 'meta_filters', action: 'bulk', filter: params[:meta], :'keys[]' => :sort, :'values[]' => params[:sort], :'keys[]' => :direction, :'values[]' => params[:direction]
			rec = MetaFilter.where(filter: params[:meta].first).first
			if rec.nil?
		Rails.logger.warn '(2)'
				redirect_to new_bulk_meta_filter_pair_url(params)
			else
		Rails.logger.warn '(3)'
				if 'Add to Filter' == params[:commit] and params[:ids].is_a?(Array) # if @ids is not nil we don't double check to make sure it's an array of ids
		Rails.logger.warn '(4)'
					redirect_to edit_bulk_meta_filter_pair_url(rec.id, {op: '+', extra_ids: params[:ids]})	
				elsif 'Remove from Filter' == params[:commit] and params[:ids].is_a?(Array) # if @ids is not nil we don't double check to make sure it's an array of ids
		Rails.logger.warn '(5)'
					redirect_to edit_bulk_meta_filter_pair_url(rec.id, {op: '-', extra_ids: params[:ids]})	
				else
		Rails.logger.warn '(6)'
					redirect_to bulk_meta_filter_pair_url(rec.id)
				end
			end
		Rails.logger.warn '(7)'
			return true
		end
		Rails.logger.warn '(8)'
		false
	end

end
