class FilesController < ApplicationController
  before_action :set_file, only: [:show, :edit, :save, :dupe, :update, :destroy, :show_cache, :create_cache, :local, :strip, :query]

	helper_method :sort_column, :sort_direction, :sort_it

  # GET /files/uncached
  # GET /files/uncached.json
  def uncached
    @files = Fyle.where(cache_file: nil)
		internal_index
  end

  # GET /files/cached
  # GET /files/cached.json
  def cached
    @files = Fyle.where.not(cache_file: nil)
		internal_index
  end

  # GET /files/unlinked
  # GET /files/unlinked.json
  def unlinked
    @files = Fyle.unlinked
		internal_index
  end

  # GET /files/linked
  # GET /files/linked.json
  def linked
    @files = Fyle.linked
		internal_index
  end

  # GET /files
  # GET /files.json
  def index
    @files = Fyle.order(sort_column + " " + sort_direction)
	
		@page_title = 'Listing Files'

		internal_index
  end

  # GET /files/1
  # GET /files/1.json
  def show
    respond_to do |fmt|
			fmt.text {
				# The following seems to work and I have no idea why
				#
				# Parameters: {"id"=>"006_local"}
				# Fyle Load (0.3ms)  SELECT "fyles".* FROM "fyles" WHERE "fyles"."id" = ? LIMIT 1  [["id", "006_local"]]
				Rails.logger.info "Oh, so you want some text?"
				# nom nom
				re = /\d\d\d-local_part(\d)/
				pos = params[:id] =~ re
				if !pos.nil?
					i = ($~[1]).to_i
					chunk(i)
				else
					if params.has_key?(:chunk)
						i = Integer(params[:chunk]) rescue false
						if false == i
							strip
						else
							chunk(i)
						end
					else
						strip
					end 
				end
			}
			fmt.all {
				Rails.logger.info fmt.inspect
			}
			# html handled automatically
		end
  end

	## used by show()

  # GET /files/1/chunk

  def chunk(c)
		# @file.snarf() at the moment is (@file.materialize())[1]
		str = (@file.materialize)[1]
		s = 1.megabyte
		data = str[(c*s)..(((c+1)*s)-1)]
		send_data( data, :disposition => 'inline', :type => 'text/plain; charset=UTF-8', :x_sendfile => true)
  end

  # GET /files/new
  def new
		@what = params[:what]
    @file = Fyle.new
  end

  # GET /files/1/edit
  def edit
		@what = @file.what # see above
  end

	def save
    respond_to do |format|
			if not params.key?(:content)
				message = "holy shit, no content"
				Rails.logger.info message
				render json: message, status: :unprocessable_entity
			end
			content = params['content']
			Rails.logger.info "params content length: #{content.length}"
			# content = params['content'].gsub!('<br>',"\n")
      if @file.save_content(content)
        format.html { }
        format.json { 
					Rails.logger.info "true #{params.keys}"
					# head :ok, content_type: "text/json"
					render json: nil
				}
      else
        format.html { }
        format.json {
					Rails.logger.info "false #{params.keys}"
					render json: "Arse", status: :unprocessable_entity
				}
      end
    end
	end

	# POST /files/1
	# POST /files/1.json
	def dupe
		make_it_new({what: "#{@file.what} (dupe)", URL: @file.URL})
	end

  # POST /files
  # POST /files.json
  def create
    make_it_new(file_params)
	end

	def make_it_new(params)
    @file = Fyle.new(params)

		@file.sanitize
		
		# TODO communicate show result to user
		support = @file.divine_type
		Rails.logger.info "FilesController.create support: #{support}"
		Rails.logger.info "FilesController.create #{@file.inspect}"

    respond_to do |format|
      if not support.blank? and not support.start_with?('*sigh*') and @file.save
        format.html { redirect_to @file, notice: 'Text file was successfully created.' }
        format.json { render action: 'show', status: :created, location: @file }
      else
				flash.alert = support
        format.html { render action: 'new' }
        format.json { render json: @file.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /files/1
  # PATCH/PUT /files/1.json
  def update
		# should be updating params
		# @file.sanitize
		t = Fyle.new(file_params)
		Rails.logger.info "little t before #{t.inspect}"
		t.sanitize
		Rails.logger.info "little t after #{t.inspect}"
		# only re-divine content type if the URL has changed
		if (@file.URL != file_params[:URL]) or @file.type_negotiation.blank?
			# TODO communicate show result to user
			support = @file.divine_type
			Rails.logger.info "FilesController.update support: #{support}"
			params[:fyle][:type_negotiation] = @file.type_negotiation
			# TODO invalidate old data associated with previous file?
		end
		Rails.logger.info "FilesController.update #{@file.inspect}"
		Rails.logger.info "waahaa #{file_params}"
    respond_to do |format|
      if @file.update(file_params)
        format.html { redirect_to @file, notice: 'Text file was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /files/1
  # DELETE /files/1.json
  def destroy
    @file.destroy
    respond_to do |format|
      format.html { redirect_to fyles_url }
      format.json { head :no_content }
    end
  end

	## custom per file paths : @file is set with set_file
	
	# GET /files/1/cache
	def show_cache
		send_file( @file.cache_file, :disposition => 'inline', :type => Fyle::MIME_TYPE[@file.type_negotiation], :x_sendfile => true)
	end

  # POST /files/1/cache
	def create_cache
    respond_to do |format|
      if @file.cache
        format.html { redirect_to @file, notice: 'Original file was cached successfully.' }
        format.json { head :no_content }
      else
        format.html { render action: 'show' }
        format.json { render json: @file.errors, status: :error_in_caching }
      end
    end
	end

  # GET /files/1/local
  def local
		# change this to send_data?
		send_file( (@file.materialize)[0], :disposition => 'inline', :type => 'text/plain; charset=UTF-8', :x_sendfile => true)
  end

  # GET /files/1/strip
  def strip
		# @file.snarf() at the moment is (@file.materialize())[1]
		send_data( (@file.materialize)[1], :disposition => 'inline', :type => 'text/plain; charset=UTF-8', :x_sendfile => true)
  end

	def query
	end

	##
	
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_file
      @file = Fyle.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def file_params
      params.require(:fyle).permit(:URL, :what, :type_negotiation)
    end

		# real index, used by index, cached, and uncached
		def internal_index
			render :index
		end

		def sort_column
			Fyle.column_names.include?(params[:sort]) ? params[:sort] : 'id'
		end
		  
		def sort_direction
			%w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
		end

		def sort_it(column)
			Fyle::column_direction(column)
		end
end
