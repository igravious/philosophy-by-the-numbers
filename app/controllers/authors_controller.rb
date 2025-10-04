class AuthorsController < ApplicationController
  before_action :set_author, only: [:show, :edit, :update, :destroy]

  # GET /authors
  # GET /authors.json
  def index
		@page_title = 'Listing Authors'

    @authors = Author.all
  end

  # GET /authors/1
  # GET /authors/1.json
  def show
  end

	# GET /authors/new/dbpedia
	def new_dbpedia
    @author = Author.new
	end

	# POST /authors/dbpedia
	# POST /authors/dbpedia.json
	def create_dbpedia
		t = true
    @author = Author.new(author_params) # can record new barf?

    @result_set = @author.from_dbpedia
		@resources = Resource.none
		if @result_set.length > 0
			begin
				ActiveRecord::Base.transaction do
					@result_set.each do |record|
						Rails.logger.info "===> #{record.inspect}"
						Rails.logger.info "---> #{record[:resource]}"
						r = Resource.new
						r.URI = record[:resource].to_s
						r.save!
						@resources << r
					end
				end
			rescue ActiveRecord::ActiveRecordError => eek
				@author.errors[:base] << eek.message
				Rails.logger.info "***> #{eek}"
				t = false
			end
		end
		Rails.logger.info "///> #{@resources}"
    respond_to do |format|
      if t
        format.html { redirect_to resources_path, notice: 'Resources successfully grabbed from DBPedia.' }
        format.json { render action: 'index', status: :created, location: @resources }
      else
        format.html { render action: 'new_via_dbpedia' }
        format.json { render json: @author.errors, status: :unprocessable_entity }
      end
    end
	end

  # GET /authors/new
  def new
    @author = Author.new
  end

  # GET /authors/new/resource
  def new_resource
    @author = Author.new(author_params)
		render :new
  end

  # GET /authors/1/edit
  def edit
  end

  # POST /authors
  # POST /authors.json
  def create
    @author = Author.new(author_params)

    respond_to do |format|
      if @author.save
        format.html { redirect_to @author, notice: 'Author was successfully created.' }
        format.json { render action: 'show', status: :created, location: @author }
      else
        format.html { render action: 'new' }
        format.json { render json: @author.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /authors/1
  # PATCH/PUT /authors/1.json
  def update
    respond_to do |format|
      if @author.update(author_params)
        format.html { redirect_to @author, notice: 'Author was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @author.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /authors/1
  # DELETE /authors/1.json
  def destroy
		# why isn't this happening automatically?
		Writing.destroy_all(:author_id => @author.id)
    @author.destroy
    respond_to do |format|
      format.html { redirect_to authors_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_author
      @author = Author.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def author_params
			params.require(:author).permit(:name, :english_name, :year_of_birth, :date_of_birth, :year_of_death, :when_died, :where, :about, texts_attributes: [:id, :name, :name_in_english, :original_year, :edition_year, :_destroy])
    end
end
