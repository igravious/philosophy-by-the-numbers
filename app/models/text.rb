class Text < ActiveRecord::Base
	has_many :writings
	has_many :authors, :through => :writings
	has_many :labelings
	has_many :tags, :through => :labelings
	has_many :includings
	accepts_nested_attributes_for :writings, :reject_if => :all_blank, :allow_destroy => true
	accepts_nested_attributes_for :authors, :reject_if => :all_blank
	accepts_nested_attributes_for :labelings, :reject_if => :all_blank, :allow_destroy => true
	accepts_nested_attributes_for :tags, :reject_if => :all_blank, :allow_destroy => true
	accepts_nested_attributes_for :includings, :reject_if => :all_blank

	belongs_to :fyle

	# TODO you know you're doing something dumb when you are enumerating an index
	ORIGINAL_LANGUAGE=[
		["Ancient Greek",1],
		["Ancient Chinese",2],
		["Early Latin",3],
		["Modern French",4],
		["New High German (1650-now)",5],
		["Modern English",6],
		["Classical Latin",7],
		["Late Latin",8],
		["Medieval Latin (14th-16th)",9],
		["Renaissance Latin",10],
		["New Latin",11],
		["Old English",12],
		["Middle English",13],
		["Early Modern English",14],
		["Old French (Langue d'oïl)",15],
		["Middle French (1300-1650)",16],
		["Danish",17],
		["Renaissance Italian",19],
		["Classical Arabic",21],
		["Modern Standard Arabic",23],
		["Judeo-Arabic",25],
		["Early New High German (1350-1650)", 27],
		["Middle High German (1050-1350)", 28]
	]

	# Duh!
	INEQUALITY=[
		["<",1],
		["=",2],
		[">",3]
	]

	attr_accessor :filter_id

	def filter_id=(val)
		@filter_id = val
	end

	def filter?
		(not @filter_id.blank?)
	end

	def filter_id
		# totes should be boolean
		self.includings.where(filter_id: @filter_id).any?
	end

	def author_names
		authors.map{ |a|
			a.english_name
		}.join(", ")
	end

	def edit_author_names
		authors.map{ |a|
			eng = a.english_name
			url = Rails.application.routes.url_helpers.edit_author_path(a)
			# Rails.logger.info "eng #{eng}: url #{url}"
			ActionController::Base.helpers.link_to(eng, url)
		}.join(", ")
	end

	def filename_suggestion
		surname = authors.map{ |a|
			a.english_name.split(' ').last
		}.join(" & ")
		textname = self.name_in_english
		(surname+' - '+textname).downcase
	end

	def tag_names
		tags.map{ |a|
			a.name
		}.join(", ")
	end

	def edit_tag_names
		tags.map{ |t|
			name = t.name
			url = Rails.application.routes.url_helpers.edit_tag_path(t)
			# Rails.logger.info "name #{name}: url #{url}"
			ActionController::Base.helpers.link_to(name, url)
		}.join(", ")
	end

	def jump_tag_names
		tags.map{ |t|
			name = t.name
			l = Labeling.find_by! tag: t, text: self
			url = Rails.application.routes.url_helpers.labeling_path(l)
			# Rails.logger.info "name #{name}: url #{url}"
			ActionController::Base.helpers.link_to(name, url)
		}.join(", ")
	end

	def author_id
	end

	def tag_id
	end

	def the_writing(author)
		if (author.id).nil?
			foo = Writing.new
		else
			foo = writings.find_by_author_id(author.id)
		end
		# Rails.logger.info "Writing #{foo}"
		# Rails.logger.info "Writing #{foo.inspect}"
		foo
		# return (foo?bar:baz)
	end

	def icon_link
	end

	def gen_cache_name
		File.basename(Tempfile.new([name_in_english, '.txt']).path)
	end

	# returns a URL
	def local_file
		Fyle.find(fyle_id).local
	end

	# returns a URL
	def strip_file
		Fyle.find(fyle_id).strip_path
	end

	# returns a URL
	def plain_file
		Fyle.find(fyle_id).plain_path
	end

	def self.column_direction(col)
		# determines the original orientation of the columns
		# label is asc A->Z
		# everything else is descending: roles_count highest->lowest, relevant on->off
		%w[name_in_english].include?(col) ? 'asc' : 'desc'
	end

end
