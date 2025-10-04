class RolesController < ApplicationController
  before_action :set_role, only: [:show, :edit, :update, :destroy]

	helper_method :wikidata_entity_url

		# @roles = Role.all.select(:label).distinct
		# @roles = Role.group(:label).count
		# @roles = Role.group(:label).count.sort_by {|_key, value| value}.reverse

		# am still trying to figure out the counter cache (very slow join)
		# https://work.stevegrossi.com/2015/04/25/how-to-count-with-activerecord/
		# https://blog.appsignal.com/2018/06/19/activerecords-counter-cache.html
	
  # GET /roles
  # GET /roles.json
  def index
		if params[:filter] == 'capacity'
			redirect_to controller: 'capacities', action: 'index_count'
		elsif params[:filter] == 'entity_id'
			@mode = 2
			Shadow.none
			@info = params[:value]
			@roles = Role.where(entity_id: params[:value])
		elsif params[:filter] == 'shadow_id'
			@mode = 1
			Shadow.none
			@info = Philosopher.find(params[:value]).english
			@roles = Role.where(shadow_id: params[:value])
		else
			@mode = 0
			Shadow.none
			@info = "all Roles"
    	# @roles = Role.all.limit(100) # just 100!
    	@roles = Role.all
		end
	
		@listing = if 0 == @mode
			'Listing '+@info
		elsif 1 == @mode
			'Listing Roles for #'+@info
		elsif 2 == @mode
			'Listing Roles for Entity Q'+@info # wikidata_entity_url(@info)
		end
		@page_title = @listing.html_safe unless @listing.nil?
		@page = params[:page]
		@roles = @roles.page @page unless @roles.nil?
  end

  # GET /roles/1
  # GET /roles/1.json
  def show
  end

  # GET /roles/new
  def new
    @role = Role.new
  end

  # GET /roles/1/edit
  def edit
  end

  # POST /roles
  # POST /roles.json
  def create
    @role = Role.new(role_params)

    respond_to do |format|
      if @role.save
        format.html { redirect_to @role, notice: 'Role was successfully created.' }
        format.json { render :show, status: :created, location: @role }
      else
        format.html { render :new }
        format.json { render json: @role.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /roles/1
  # PATCH/PUT /roles/1.json
  def update
    respond_to do |format|
      if @role.update(role_params)
        format.html { redirect_to @role, notice: 'Role was successfully updated.' }
        format.json { render :show, status: :ok, location: @role }
      else
        format.html { render :edit }
        format.json { render json: @role.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.json
  def destroy
    @role.destroy
    respond_to do |format|
      format.html { redirect_to roles_url, notice: 'Role was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_role
      @role = Role.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def role_params
      params.require(:role).permit(:shadow_id, :entity_id, :label)
    end
end
