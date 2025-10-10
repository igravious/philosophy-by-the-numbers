class DictionariesController < ApplicationController
  before_action :set_dictionary, only: [:show, :edit, :update, :destroy, :entry]

	# Collections

  # GET /dictionaries
  # GET /dictionaries.json
  def index
		@page_title = 'Listing Reference Works'

    @dictionaries = Dictionary.all

    # Get algorithm version from params or use default
    @algorithm_version = params[:algorithm_version] || '2.0'

    # Fetch canonicity weights for display
    @weights = CanonicityWeights.where(algorithm_version: @algorithm_version, active: true)
                                 .index_by(&:source_name)

    # Get list of available algorithm versions for dropdown
    @algorithm_versions = CanonicityWeights.select(:algorithm_version)
                                            .distinct
                                            .order(:algorithm_version)
                                            .pluck(:algorithm_version)

    # Count philosophers for each encyclopedia flag
    @philosopher_counts = {}
    Dictionary.where.not(encyclopedia_flag: nil).pluck(:encyclopedia_flag).uniq.each do |flag|
      @philosopher_counts[flag] = ::Philosopher.where(flag => true).count
    end
  end

	# GET /dictionaries/compare
	def compare
		#@dictionaries = Dictionary.all
		@units = Unit.all
		@plucked_dicts = Unit.uniq.pluck(:dictionary_id)
		@dictionaries = Dictionary.where(id: @plucked_dicts) # only dictionaries with entries in the units table
	end

  # GET /dictionaries/1
  # GET /dictionaries/1.json
  def show
  end

	def entry
		# Fixed: Use security configuration for file path validation
		file_id = SecurityConfig.validate_file_id(params[:id])
		file_path = Rails.root.join('public', 'comparison', "#{file_id}.txt")
		
		# Ensure the resolved path is within the expected directory
		unless file_path.to_s.start_with?(Rails.root.join('public', 'comparison').to_s)
			raise ArgumentError, "File path is outside allowed directory"
		end
		
		send_file(file_path, :disposition => 'inline', :type => 'text/plain; charset=UTF-8', :x_sendfile => true)
	end

  # GET /dictionaries/new
  def new
    @dictionary = Dictionary.new
  end

  # GET /dictionaries/1/edit
  def edit
  end

  # POST /dictionaries
  # POST /dictionaries.json
  def create
    @dictionary = Dictionary.new(dictionary_params)

    respond_to do |format|
      if @dictionary.save
        format.html { redirect_to @dictionary, notice: 'Dictionary was successfully created.' }
        format.json { render action: 'show', status: :created, location: @dictionary }
      else
        format.html { render action: 'new' }
        format.json { render json: @dictionary.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dictionaries/1
  # PATCH/PUT /dictionaries/1.json
  def update
    respond_to do |format|
      if @dictionary.update(dictionary_params)
        format.html { redirect_to @dictionary, notice: 'Dictionary was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @dictionary.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dictionaries/1
  # DELETE /dictionaries/1.json
  def destroy
    @dictionary.destroy
    respond_to do |format|
      format.html { redirect_to dictionaries_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dictionary
      @dictionary = Dictionary.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dictionary_params
      params.require(:dictionary).permit(:title, :long_title, :URI, :current_editor, :contact, :organisation, :encyclopedia_flag)
    end
end
