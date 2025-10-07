class TextsController < ApplicationController
  before_action :set_text, only: [:show, :edit, :update, :destroy]
	before_action :set_filters, only: [:excluded, :included, :filtered, :index]

	helper_method :sort_column, :sort_direction, :sort_it

  # GET /texts/excluded
  # GET /texts/excluded.json
  def excluded
    @texts = Text.where(include: false)
		render :index
  end

  # GET /texts/included
  # GET /texts/included.json
  def included
    @texts = Text.where(include: true)
		render :index
  end

	def process_filters
		# @texts = Text.filter(params(:tag_id))
		# all = Text.all
		# there's a method called all now
		if @tag_id.blank?
			texts_set1 = all
		else
			texts_set1 = Text.where(id: Labeling.where(tag_id: @tag_id).collect{|l|l.text_id})
		end
		if '<' == @inequality
			if !@original_year.blank? # TODO validation?
				texts_set2 = Text.where("original_year < ?", @original_year)
			else
				texts_set2 = all
			end
		elsif '=' == @inequality
			if !@original_year.blank? # TODO validation?
				texts_set2 = Text.where("original_year = ?", @original_year)
			else
				texts_set2 = all
			end
		elsif '>' == @inequality
			if !@original_year.blank? # TODO validation?
				texts_set2 = Text.where("original_year > ?", @original_year)
			else
				texts_set2 = all
			end
		else
			texts_set2 = all
		end
		if @name_in_english.blank?
			texts_set3 = all
		else
			texts_set3 = Text.where("name_in_english LIKE ?", "%#{@name_in_english}%")
		end
		if @author_name.blank?
			texts_set4 = all
		else
			texts_set4 = Text.where(id: Writing.where(author_id: Author.where(english_name: @author_name)).pluck(:text_id))
		end
		@texts = texts_set1 & texts_set2 & texts_set3 & texts_set4
	end

	def filtered
		process_filters
		render :index
	end

	def all
		# railscasts.com/episodes/228-sortable-table-columns
		# Text.all
		Text.order(sort_column + " " + sort_direction)
	end

	def archive
		begin
			@files = Fyle.linked
			#@str = @files.to_a.keep_if{|f|!f.health.blank? and (f.health < 10.0) and (f.file_size < 1.megabyte)} #.map(&:id)
			@str = @files.to_a.keep_if{|f|!f.health.blank? and (f.health < 10.0)} #.map(&:id)
			`rm archive/*`
			`rm archive.zip`
			@files.each{|f|
				File.write("archive/#{sprintf('%03d',f.id)} – #{f.what}.txt", f.snarf.force_encoding("UTF-8"))
			}
			`zip -j -r archive.zip archive/*`
			send_file 'archive.zip'
		rescue StandardError => e
			Rails.logger.warn e.message
			Rails.logger.warn e.backtrace.first
		end
	end

  # GET /texts
  # GET /texts.json
	# GET /texts.xml
  def index
		# Rails.logger.info "required #{Kernel::required($LOADED_FEATURES)}"
		# Rails.logger.info "====> #{request.public_methods}"
		# TODO ?chunked=true
		respond_to do |format|
			format.html do
				@page_title = "Listing Texts"
				process_filters
			end
			format.csv do
				paper(6) # !!
				# render plain: "OK"
				render :index, content_type: "text/plain"
			end
			format.voyant do
				paper(6)
				# render plain: "OK"
				render :index, content_type: "text/plain"
			end
			format.json { @texts = all }
			format.zip do
			end
			format.xml do
			 	if params.key?(:snapshot)
					snapshot_xml params[:snapshot]
					render :snapshot
				else
					xml
					# render default
				end
			end
		end
  end

	def to_boolean(str)
		str.downcase == 'true'
	rescue NoMethodError, ArgumentError
		return false
	end

	# TODO DRY?
	def count_docs snap
		query = Elasticsearch::Client.new log: false
		begin
			res = query.search(index: snap, type: GlobalConstants::DOC_TYPE, search_type: 'count') {}
			return res['hits']['total'].to_i
		rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
			return 0
		end
	end

	# assume parts != true for now
	def snapshot_xml label
		@papers = []
		begin
			client = Elasticsearch::Client.new log: true
			# don't support labels yet, so for the moment label is a numeric suffix
			snap = 'snapshot'+label
			res = client.get(index: snap, type: GlobalConstants::METADATA, id: 0)
			e = res['_source']
			@event = OpenStruct.new(url: e['url'], year: e['year'])
			i = 0
			while i < count_docs(snap)
				res = client.get(index: snap, type: GlobalConstants::DOC_TYPE, id: i)
				p = res['_source']
				paper_url = Fyle.snapshot_url(label, p['uid'])
				content_url = File.basename(paper_url)
				paper = OpenStruct.new(content_url: content_url, paper_url: paper_url, year: p['year'], title: p['title'])
				paper.authors = []
				p['authors']['array'].each do |a|
					author = OpenStruct.new(name: a['author'])
					paper.authors.push(author)
				end
				@papers.push(paper)
				i += 1
			end
		rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
			Rails.logger.info e
		rescue Exception => msg
			Rails.logger.error msg
		end
	end

	def xml
		if to_boolean(params[:parts])
			@events = [OpenStruct.new(url: 'http://www.dh2016.org/', year: 2016)]
			@files = Fyle.all
			@papers = []
			@files.each do |file|
				text = file.text
				if !text.nil?
					if !text.include
						next
					end

					snarfed = file.snarf
					Rails.logger.info "#{snarfed.size.to_s.rjust(8, " ")} <- #{text.name_in_english}"
					chunk = 1.megabyte

					if snarfed.size > chunk
						# 0 ..  1.mb - 1
						# 1.mb .. 2.mb - 1
						# .
						# .
						# (n-1).mb .. n.mb -1
						# n.mb .. paper.size
						n = snarfed.size / chunk
						rem = snarfed.size % chunk
						i = 0
						# do this outside the loop
						authors = []
						text.authors.each do |author|
							wrote = text.the_writing(author)
							# if the role field is not explicitly set assume that the author is the author
							if wrote.role.nil? or wrote.role == Writing::AUTHOR
								author = OpenStruct.new(name: author.english_name)
								authors.push(author)
							end
						end
						while i < n
							basename = File.basename(file.chunk_path(i))
							title = "#{text.name_in_english} (Part #{i+1})"
							paper = OpenStruct.new(content_url: basename, paper_url: file.chunk_path(i), year: text.original_year, title: title)
							paper.size = chunk
							# same for every one
							paper.authors = []
							authors.each do |author|
								paper.authors.push(author)
							end
							# content = OpenStruct.new(chunk: i, size: chunk, url: file.chunk_url(i))
							# paper.contents.push(content)
							@papers.push(paper)
							i = i+1
						end
						basename = File.basename(file.chunk_path(n))
						title = "#{text.name_in_english} (Part #{n+1})"
						paper = OpenStruct.new(content_url: basename, paper_url: file.chunk_path(n), year: text.original_year, title: title)
						paper.size = rem
						# same for every one
						paper.authors = []
						authors.each do |author|
							paper.authors.push(author)
						end
						@papers.push(paper)
						# content = OpenStruct.new(chunk: n, size: rem, url: file.chunk_url(i))
						# paper.contents.push(content)
					else
						paper = OpenStruct.new(content_url: File.basename(file.plain_path), paper_url: file.plain_path, year: text.original_year, title: text.name_in_english)
						paper.size = snarfed.size
						paper.authors = []
						text.authors.each do |author|
							wrote = text.the_writing(author)
							# if the role field is not explicitly set assume that the author is the author
							if wrote.role.nil? or wrote.role == Writing::AUTHOR
								author = OpenStruct.new(name: author.english_name)
								paper.authors.push(author)
							end
						end
						@papers.push(paper)
					end
				end
			end
		elsif to_boolean(params[:chunked])
			@events = [OpenStruct.new(url: 'http://www.dh2016.org/', year: 2016)]
			@files = Fyle.all
			@papers = []
			@files.each do |file|
				text = file.text
				if !text.nil?
					if !text.include
						next
					end

					paper = OpenStruct.new(content_url: file.plain, paper_url: fyle_url(file), year: text.original_year, title: text.name_in_english)

					snarfed = file.snarf
					Rails.logger.info "#{snarfed.size.to_s.rjust(8, " ")} <- #{text.name_in_english}"
					chunk = 1.megabyte
					if snarfed.size > chunk
						# 0 ..  1.mb - 1
						# 1.mb .. 2.mb - 1
						# .
						# .
						# (n-1).mb .. n.mb -1
						# n.mb .. paper.size
						paper.contents = []
						n = snarfed.size / chunk
						rem = snarfed.size % chunk
						i = 0
						while i < n
							content = OpenStruct.new(chunk: i, size: chunk, url: "#{file.plain}?chunk=#{i}")
							paper.contents.push(content)
							i = i+1
						end
						content = OpenStruct.new(chunk: n, size: rem, url: "#{file.plain}?chunk=#{i}")
						paper.contents.push(content)
					else
						paper.size = snarfed.size
					end

					paper.authors = []
					text.authors.each do |author|
						wrote = text.the_writing(author)
						# if the role field is not explicitly set assume that the author is the author
						if wrote.role.nil? or wrote.role == Writing::AUTHOR
							author = OpenStruct.new(name: author.english_name)
							paper.authors.push(author)
						end
					end
					@papers.push(paper)
				end
			end
		else
			paper
		end
	end

	def paper(tag_id = nil)
		text_set = Text.all
		unless tag_id.nil?
			tag_set = Labeling.where(tag_id: tag_id)
			text_set = text_set.where(id: tag_set.pluck(:text_id))
		end
		text_set_f = text_set.where.not(fyle_id: nil)
		@files = Fyle.where(id: text_set_f.pluck(:fyle_id)).where.not(health: nil)
		@events = [OpenStruct.new(url: 'http://www.dh2016.org/', year: 2016)]
		@papers = []
		@files.each do |file|
			text = file.text # Fyle has_one Text
			if !text.nil?
				if file.health.nil?
					next
				end
				# paper = OpenStruct.new(content_url: file.plain, paper_url: fyle_url(file), year: text.original_year, title: text.name_in_english)
				paper = OpenStruct.new(content_url: File.basename(file.plain_path), paper_url: file.plain_path, year: text.original_year, title: text.name_in_english)
				paper.authors = []
				text.authors.each do |author|
					wrote = text.the_writing(author)
					# if the role field is not explicitly set assume that the author is the author
					if wrote.role.nil? or wrote.role == Writing::AUTHOR
						author = OpenStruct.new(name: author.english_name)
						paper.authors.push(author)
					end
				end
				@papers.push(paper)
			end
		end
	end

	private
		def set_filters

			if params.key?(:filter_id) and not params['filter_id'].blank?
				@filter = Filter.find(params['filter_id'])
				# could i have this all in a filter? and use form_for?
				@includings      = @filter.includings.pluck(:text_id)
				@tag_id          = @filter.tag_id
				@original_year   = @filter.original_year
				@inequality      = @filter.inequality
				@name_in_english = @filter.name_in_english
				#@filter.id = nil
			else
				@tag_id          = params['tag_id']
				@original_year   = params['original_year']
				@inequality      = params['inequality']
				@name_in_english = params['name_in_english']
				@author_name     = params['author_name']

				if params.key?(:filter_name) and not params['filter_name'].blank?
					@filter = Filter.find_by_name(params['filter_name'])
					if @filter.nil?
						# not found, new!
						@filter = Filter.new
						@includings = []
						@filter.name = params['filter_name']
						@filter.tag_id = @tag_id
						@filter.original_year = @original_year
						@filter.inequality = @inequality
						@filter.name_in_english = @name_in_english
						@filter.save!
					else
						# found, update!
						#@tag_id          = @filter.tag_id
						#@original_year   = @filter.original_year
						#@inequality      = @filter.inequality
						#@name_in_english = @filter.name_in_english
						@includings      = @filter.includings.pluck(:text_id)
						@filter.update_attributes!({tag_id: @tag_id, original_year: @original_year, inequality: @inequality, name_in_english: @name_in_english})
					end
					#@filter.id = nil
				else
					@filter = Filter.new
					@includings = []
				end
			end

			require 'the_git'

			# g = git_open
			@commit_hashes = []
			# value = 0
			# @num_commits = g.log.each do |commit|
			# 	@commit_hashes.push([commit.to_s, value])
			# 	value += 1
			# end.length
			@num_tracked = -1
			# Rails.logger.info "# commits #{@num_commits} - #{@commit_hashes}"

		end

	###
	#
		public
	# Members
	#
	###


  # GET /texts/1
  # GET /texts/1.json
  def show
  end

	# GET /texts/:id/from_fyle
	# :id is a Fyle id, not a Text id !
	# though params[:text_fyle_id] is already permitted
	def from_fyle
    @text = Text.new
		@text.fyle_id = params[:id]
		render :new
	end

  # GET /texts/new
  def new
    @text = Text.new
		# if params[:text_fyle_id].present?
		# 	@text.fyle_id = params[:text_fyle_id]
		# end
  end

  # GET /texts/1/edit
  def edit
		@text.filter_id = params['filter_id']
  end

  # POST /texts
  # POST /texts.json
  def create
		# behold the mighty error handling
		# only catch specific excpetions anto, let rails give 404s and 500s
		begin
			author_id = params[:text].delete(:author_id)
    	@text = Text.new(text_params)
			t = @text.save # save the text bit and author bit separately of each other
			if !author_id.blank?
				@author = Author.find(author_id) # will throw
				if t
					Writing.new({author_id: @author.id, text_id: @text.id}).save! # will throw
				end
			end
		rescue ActiveRecord::RecordNotFound => not_found # frick
			@text.errors[:base] << "Could not find specific author with id: #{author_id}"
			t = false
		rescue ActiveRecord::RecordError => eek # frick
			@text.errors[:base] << eek.message
			t = false
		end

    respond_to do |format|
      if t
        format.html { redirect_to @text, notice: "Record was successfully created." }
        format.json { render action: 'show', status: :created, location: @text }
      else
        format.html { render action: 'new' }
        format.json { render json: @text.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /texts/1
  # PATCH/PUT /texts/1.json
  def update
		begin
			t = true
			author_id = params[:text].delete(:author_id)
			if !author_id.blank?
				@author = Author.find(author_id) # could throw
				# same Text and new Author so create new Writing (no dupes)
				# no role set yet
				Writing.new({author_id: @author.id, text_id: @text.id}).save! # could throw
			end
			tag_id = params[:text].delete(:tag_id)
			if !tag_id.blank?
				@tag = Tag.find(tag_id) # could throw
				# same Text and new Tag so create new Labeling (no dupes)
				Labeling.new({tag_id: @tag.id, text_id: @text.id}).save! # could throw
			end
			Rails.logger.info(params[:text][:tags_attributes])
		rescue ActiveRecord::RecordNotFound => not_found # frick
			@text.errors[:base] << "Could not find specific author with id: #{author_id}"
			t = false
		rescue ActiveRecord::RecordError => eek # frick
			@text.errors[:base] << eek.message
			t = false
		end

    respond_to do |format|
			if @text.update(text_params) and t
        format.html { redirect_to @text, notice: 'Record was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @text.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /texts/1
  # DELETE /texts/1.json
  def destroy
		# why isn't this happening automatically?
		Writing.destroy_all(:text_id => @text.id)
    @text.destroy
    respond_to do |format|
      format.html { redirect_to texts_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_text
      @text = Text.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
		# TODO: Unpermitted parameter: filter_id ?
    def text_params
			# when you add an associatio, add the params
			params.require(:text).permit(:name, :name_in_english, :original_year, :edition_year, :author_id, :fyle_id, :original_language, authors_attributes: [:id, :name, :english_name, :year_of_birth, :date_of_birth, :year_of_death, :when_died, :where, :about, :_destroy], tags_attributes: [:id, :name, :_destroy], writings_attributes: [:id, :role])
    end

		def sort_column
			Text.column_names.include?(params[:sort]) ? params[:sort] : 'id'
		end
		  
		def sort_direction
			%w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
		end

		def sort_it(column)
			Text::column_direction(column)
		end
end
