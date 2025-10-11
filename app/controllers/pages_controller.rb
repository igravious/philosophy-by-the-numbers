class PagesController < ApplicationController

	def index
		# New landing page
	end

	def about
		# About/welcome page with Rails info
	end

	def welcome
		# Redirect to about page
		redirect_to about_path
	end

	def info
		require 'rouge'
	end

	def export
		@total = Text.all
		saffron = Labeling.where(tag_id: 5)
		@saffron = Text.where(id: saffron.pluck(:text_id))
		lda = Labeling.where(tag_id: 6)
		@lda = Text.where(id: lda.pluck(:text_id))
		@lda_f = @lda.where.not(fyle_id: nil)
		@lda_fh = Fyle.where(id: @lda_f.pluck(:fyle_id)).where.not(health: nil)
		@page_title = "Export Related Stuff"
	end

	def philosoraptor
		require 'philosoraptor'
		@image_url = Philosoraptor::create(params['top'], params['bottom'])
	end

	def landing
		require 'philosoraptor'
		@launch_url = inquiry_url
		@image_url = Philosoraptor::cache_create('Code + Philosophy', '= ?')
	end

	def inquiry
		@inquiries = [OpenStruct.new(:name => "Saffron Inquiry v.1", :url => compare_dictionaries_url )]
	end

	def questions
		@page_title = 'Questions & Answers'

		@inquiries = [OpenStruct.new(:name => "Saffron Inquiry v.1", :url => compare_dictionaries_url )]
	end

	# https://www.elastic.co/guide/en/elasticsearch/reference/2.2/index.html

	def search
		if params.key?('q')
			require 'elastic_helper'
			elastic(false) do |client|
				if client.nil?
					@total = -1
					flash[:alert] = "Search functionality borked."
				else
					snap = latest_snap
					@search_term = params['q']
					if params['f'].nil?
						@from = 0
					else
						# should check that it is in range
						@from = params['f'].to_i
					end
					@size = 5 # params['s']
					res = client.search(index:snap, body:{ query:{ match_phrase:{ content:@search_term }}, from:@from, size:@size, highlight:{ fields:{ content:{}}}})
					# p res.keys
					# ["took", "timed_out", "_shards", "hits"]
					# p res["hits"].keys
					# ["total", "max_score", "hits"]
					@total = res["hits"]["total"]
					# p res["hits"]["total"]
					@hits = res["hits"]["hits"]
					# Rails.logger.info res.keys
					@hits.each do |h|
						t = Text.where(name_in_english: h['_source']['title']).first
						h['text'] = t
						if t.nil? # :( file name has changed independently, wonder how that happened? :(
							f = nil
						else
							f = Fyle.find(t.fyle_id)
						end
						h['fyle'] = f
					end
				end
			end
		elsif params.length > 2
			@total = -1
			flash[:alert] = "Bad search query parameter."
		end
	end

	require 'rdf'
	require 'rdf/ntriples'
	# require 'json/ld'

	def semantic_web
		begin
			term = params['term']
			meros = RDF::Graph.new
			labels = {}
			term.split(',').each do |t|
				begin
					meros.insert(RDF::Graph.load("db/wikidata/meros_#{t}.nt"))
					labels.merge!(Marshal.load(File.read("db/wikidata/labels_#{t}.bin")))
				rescue IOError
					render html: "<strong>I don't know about #{term} </strong>".html_safe
					return
				end
			end
			Rails.logger.info meros
			Rails.logger.info labels
			arbitrary_name(meros, labels)
			render :springy
		rescue Exception => e
			Rails.logger.error e
			render html: "<strong>Something went wrong. Maybe don't do that again?</strong>".html_safe
			return
		end
	end

	def springy
		# https://github.com/ruby-rdf/rdf/blob/develop/lib/rdf/writer.rb
		# meros = RDF::Graph.load("http://ruby-rdf.github.com/rdf/etc/doap.nt")
		#
		term = params['term']

		# Show selection page if no term provided
		if term.blank?
			render 'springy_selection'
			return
		end

		meros = RDF::Graph.new
		labels = {}
		term.split(',').each do |t|
			meros.insert(RDF::Graph.load("db/wikidata/meros_#{t}.nt"))
			labels.merge!(Marshal.load(File.read("db/wikidata/labels_#{t}.bin")))
		end
		Rails.logger.info meros
		Rails.logger.info labels
		arbitrary_name(meros, labels)
	end

	def springy_from_wiki # straight from wiki
		term = params['term']
		require 'wikidata'
		w = Wikidata::Client.new
		meros = []
		labels = []
		term.split(',').each do|t|
			meros, labels = w.recurse_query(t)
		end
		arbitrary_name(meros, labels)
	end

	def arbitrary_name(meros, labels)
		remember = []
		@nodes = []
		@edges = []
		edge_color = {'P279' => 'CCBBAA', 'P361' => '33BB77'} # edges and nodes should convey semantic info via CSS
		meros.each do |triple|
			entity_from = (triple.subject.to_s).split('/').last
			label_from = labels[entity_from]
			entity_to = (triple.object.to_s).split('/').last
			label_to = labels[entity_to]
			node_color = (params['term'].split(',').include?(label_from) ? 'CC3344': '333333')
			if !remember.include? triple.subject
				node = OpenStruct.new(color: node_color, label: label_from, entity: entity_from)
				remember.push(triple.subject)
				@nodes.push(node)
			end
			node_color = (params['term'].split(',').include?(label_to) ? 'CC3344': '333333')
			if !remember.include? triple.object
				node = OpenStruct.new(color: node_color, label: label_to, entity: entity_to)
				remember.push(triple.object)
				@nodes.push(node)
			end
			pred_label = (triple.predicate.to_s).split('/').last
			edge = OpenStruct.new(from: entity_from, to: entity_to, color: edge_color[pred_label], label: pred_label)
			@edges.push(edge)
		end
		Rails.logger.info @edges
		Rails.logger.info @nodes
	end

	def dracula
	end

	def collect
	end

	def do_pome
		@words = nil
		if params.key?('q')
			require 'wordnet'
			q = params['q']
			lemmas = WordNet::Lemma.find_all(q)
			synsets = lemmas.map { |lemma| lemma.synsets }
			@words = synsets.flatten
			render 'pome'
		end
	end

	def pome
		@words = nil
	end

	# require where needed?
	require 'delivery'

	def do_paper
		d = Delivery.new

		# @delivery.identifier = params['pages_controller_delivery']['identifier']
		# @delivery.location = params['pages_controller_delivery']['location']
		# @delivery.date = params['pages_controller_delivery']['date']
		d.identifier = params['delivery']['identifier']
		d.location = params['delivery']['location']
		d.date = params['delivery']['date']

		# path = Rails.root.to_s+"???"
		# path = "/home/anthony/LaTeX/fragments.pdf"
		# send_file(  path, :disposition => 'inline', :type => 'application/pdf', :x_sendfile => true)
		d.play = 'hmm'
		d.numbered = 9
		d.amount = 256 # constant?

		require 'texify'
		@result = texify(d)
		if @result.nil? or @result == false
			render :paper_delivery_error
		else
			path = "/home/anthony/LaTeX/fragments.pdf"
			send_file(  path, :disposition => 'inline', :type => 'application/pdf', :x_sendfile => true)
		end
	end

	def paper
		# @delivery = Delivery.new
		# @delivery = OpenStruct.new(identifier: nil, location: nil, date: nil)
		# view expects instance variable @delivery
		@delivery = Delivery.new
	end

	def dashboard
		@page_title = "Database Dashboard"
		@table_counts = {}

		ActiveRecord::Base.connection.tables.each do |table|
			next if table == 'schema_migrations' # Skip schema migrations
			result = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}")
			count = result.first['COUNT(*)']  # Access by column name
			@table_counts[table] = count
		end

		# Sort by count descending for better display
		@table_counts = @table_counts.sort_by { |table, count| -count }.to_h
	end

end
