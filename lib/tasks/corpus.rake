namespace :corpus do

	def foo
		begin
		rescue
		end
	end

		# client.transport.reload_connections!
		# client.cluster.health
		# client.search q: 'test'
		# client.search index: 'corpus', body: { query: { match: { snapshot: um? } } }
	
	#def count_snapshots
	#	query = Elasticsearch::Client.new log: true
	#	begin
	#		res = query.search(index: 'corpus', type: 'snapshot', search_type: 'count') {}
	#		return res['hits']['total']
	#	rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
	#		return 0
	#	end
	#end

  desc "Show a list of snapshots"
  task :list, [:type] => :environment  do |t, args|
		require 'elasticsearch'
		begin
			elastic(false) do |client|
				if client.nil?
					@total = -1
					flash[:alert] = "Search functionality borked."
				else
					count = count_snaps
					if 0 == count
						STDOUT.puts "There are no snapshots"
					else
						STDOUT.puts "Number of snapshots: #{count}"
						case args.type
						when 'label'
						else
						end
					end
				end
			end
		rescue Exception => msg
			STDERR.puts "Very bad juju in list: #{msg}"
		end
  end

	desc "Find term within a snapshot"
	task :find, [:term] => :environment do |t, args|
		require 'elasticsearch'
		begin
			count = count_snapshots
			if 0 == count
				STDOUT.puts "There are no snapshots"
			else
				STDOUT.puts "Searching for #{args.term} within snapshot #{count}"
				query = Elasticsearch::Client.new log: false
				# res = query.search(index: 'corpus', type: 'snapshot', id: { query: { match: { content: args.term } } })
				# res = query.search(index: 'corpus', type: 'snapshot', query: { query_string: { query: args.term}})
				p res.keys
			end
		rescue Exception => msg
			STDERR.puts "Very bad juju in find: #{msg}"
		end
	end

  desc "Take a snapshot"
  task :take, [:url, :year] => :environment do |t, args|
		require 'elasticsearch'
		begin
			next_id = count_snapshots + 1
			client = Elasticsearch::Client.new log: false
			@event = OpenStruct.new(url: args.url, year: args.year)
			@files = Fyle.all
			@papers = []
			@files.each do |file|
				text = file.text
				if !text.nil?
					if !text.include
						next
					end
					# content = Base64.encode64(file.snarf)
					paper = OpenStruct.new(content: file.snarf, year: text.original_year, title: text.name_in_english)
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
			body = Jbuilder.encode do |json|
				json.events do 
					json.event do
						json.url @event.url
						json.year @event.year
						n = 0
						json.array @papers do |paper| json.paper do
							json.content paper.content
							json.year paper.year
							json.title paper.title
							json.authors do json.array paper.authors do |author|
								json.author author.name
							end
							end
							n += 1
						end
						end
					end
				end
			end
			client.index(index: 'corpus', type: 'snapshot', id: next_id, body: body)
			STDOUT.puts "Created snapshot with id #{next_id} with #{n} paper(s)"
		rescue Exception => msg
			STDERR.puts "Very bad juju in take: #{msg}"
		end
	end

	# that's not a nuke, _this_ is a nuke
	# curl -XDELETE 'http://localhost:9200/corpus/'
  desc "Nuke a snapshot"
  task nuke: :environment do
		require 'elasticsearch'
		begin
			the_id = count_snapshots
			client = Elasticsearch::Client.new log: true
			if 0 == the_id
				STDOUT.puts "There are no snapshots to delete"
			else
				client.delete(index: 'corpus', type: 'snapshot', id: the_id)
				STDOUT.puts "Deleted snapshot with id #{the_id}"
			end
		rescue Exception => msg
			STDERR.puts "Very bad juju in nuke: #{msg}"
		end
	end

	#
	# TRY AGAIN !
	#
	
	DOC_TYPE = 'philosophical text'.freeze
	METADATA = 'metadata'.freeze

	def elastic(log_switch)
		require 'elasticsearch'
		begin
			name = caller[0]
			# STDOUT.puts "called from #{name}"
			ec = Elasticsearch::Client.new log: log_switch
			yield ec
		rescue Exception => msg
			STDERR.puts "Very bad juju in #{name}: #{msg}"
		end
	end

	def count_docs snap
		query = Elasticsearch::Client.new log: false
		begin
			res = query.search(index: snap, type: DOC_TYPE, search_type: 'count') {}
			return res['hits']['total'].to_i
		rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
			return 0
		end
	end

	def args_to_snap args
		return 'snapshot'+(args.snap.to_i).to_s
	end

	desc "PUT"
	# task PUT: :environment
  # task :PUT, [:snap, :text] => :environment do |t, args|
  task :PUT, [:snap, :text] => :environment do |t, args|
		elastic(true) do |client|
			snap = args_to_snap args
			text_id = count_docs(snap) + 1
			client.index(index: snap, type: DOC_TYPE, id: text_id, body: { content: args.text })
		end
	end

	def count_snaps
		query = Elasticsearch::Client.new log: false
		begin
			res = query.get(index: 'corpus', type: 'snapshots', id: 0) {}
			counter = res['_source']['counter']
			return counter.to_i
		rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
			return 0
		end
	end

	def latest_snap
		'snapshot'+(count_snaps.to_s)
	end

	desc "TAKE"
	task :TAKE, [:url, :year] => :environment do |t, args|
		elastic(false) do |client|
			counter = count_snaps+1
			next_snap = 'snapshot'+(counter.to_s)
			@event = OpenStruct.new(url: args.url, year: args.year)
			@files = Fyle.all
			@papers = []
			@files.each do |file|
				text = file.text
				if !text.nil?
					if !text.include
						next
					end
					# content = Base64.encode64(file.snarf)
					paper = OpenStruct.new(uid: file.id, content: file.snarf, year: text.original_year, title: text.name_in_english)
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

			client.index(index: next_snap, type: METADATA, id: 0, body: { url: @event.url, year: @event.year })
			STDOUT.puts "Stored metadata for snapshot #{next_snap}"
			n = 0
			@papers.each do |paper|
				body = Jbuilder.encode do |json|
					json.uid paper.uid
					json.content paper.content
					json.year paper.year
					json.title paper.title
					json.authors do json.array paper.authors do |author|
						json.author author.name
					end
					end
				end
				client.index(index: next_snap, type: DOC_TYPE, id: n, body: body)
				n += 1
			end
			STDOUT.puts "Created indexed snapshot #{next_snap} with #{n} paper(s)"
			client.index(index: 'corpus', type: 'snapshots', id: 0, body: { counter: counter })
		end
	end

	desc "MAP"
	task MAP: :environment do
		elastic(true) do |client|
			# curl -XGET 'http://localhost:9200/_mapping?pretty'
			client.indices.get_mapping
		end
	end

	desc "LOOK"
	task :LOOK, [:snap, :text] => :environment do |t, args|
		elastic(false) do |client|
			snap = args_to_snap args
			res = client.search(index: snap, body: { query: { match_phrase: { content: args.text } }, highlight: { fields: { content: {} } } })
			# p res.keys
			# ["took", "timed_out", "_shards", "hits"]
			# p res["hits"].keys
			# ["total", "max_score", "hits"]
			p res["hits"]["total"]
			res["hits"]["hits"].each do |h|
				# ["_index", "_type", "_id", "_score", "_source", "highlight"]
				# p h.keys
				p h['_id']
				p h["_score"]
				p h["highlight"]
				# p h['_source'].keys
				# ["content", "year", "title", "authors"]
				p h['_source']['title']
				p h['_source']['year']
			end
		end
	end

	desc "NUKE"
	task :NUKE, [:snap] => :environment do |t, args|
		elastic(true) do |client|
			snap = args_to_snap args
			client.indices.delete(index: snap)
		end
	end


	desc "WIBBLE"
	task WIBBLE: :environment do |t, args|
		Rails.logger.info "groobiest"
	end

	desc "number of snapshots"
	task TOTAL: :environment do
		elastic(false) do |client|
			if client.nil?
				@total = -1
				flash[:alert] = "Search functionality borked."
			else
				count = count_snaps
				if 0 == count
					STDOUT.puts "There are no snapshots"
				else
					STDOUT.puts "Number of snapshots: #{count}"
				end
			end
		end
	end

	########
	#
	#  G I T
	#
	########

	require 'the_git'

	desc "Version Control: Nuke"
	task GIT_NUKE: :environment do
		STDOUT.puts "Issue a `rm -rf #{corpus_folder}/.git' with care"
	end

	desc "Version Control: Total files, those missing locally, which are irregular"
	task GIT_STAT1: :environment do
		g = git_open
		# this chdir doesn't do much at the moment because 
		# the local_file attributes is stored as an absolute path
		g.chdir do
			the_fyles do |total, missing, irregular|
				puts "total: #{total}\nmissing: #{missing}\nirregular: #{irregular}"
			end
		end
	end

	desc "Version Control: Show file details"
	task GIT_FILES: :environment do
		g = git_open
		# this chdir doesn't do much at the moment because 
		# the local_file attributes is stored as an absolute path
		g.chdir do
			the_fyles(true)
		end
	end

	desc "Version Control: Info about tracked local corpus files"
	task GIT_STAT2: :environment do
		g = git_open
		begin
			g.chdir do
				# ugh, this is inefficient!
				untracked = untracked_fyles(g).collect{|x|x.local_file}
				fyles = the_fyles
				texts = fyles.find_all{|x|(Text.find_by fyle_id: x.id)}
				puts "corpus: #{fyles.length}\nuntracked: #{untracked.length}\ntexts: #{texts.length}"
			end
		rescue Exception => e
			STDERR.puts "GIT_LOCAL #{e.class}"
			STDERR.puts e.message
		end
	end

	def vocal_commit(git, commit_msg)
		git.commit(commit_msg)
		STDOUT.puts(commit_msg)
	end

	# must be untracked ?
	def track_em(git)
		git.chdir do
			untracked = untracked_fyles(git).collect{|x|x.local_file}
			git.add(untracked)
			vocal_commit(git,"#{untracked.length} baking in the oven")
		end
	end

	desc "Version Control: Track untracked files"
	task GIT_TRACK: :environment do
		g = git_open
		begin
			track_em(g)
		rescue Exception => e
			STDERR.puts "GIT_TRACK #{e.class}"
			STDERR.puts e.to_s.lines.first
		end
	end

	# TODO a proper status
	desc "Version Control: Status"
	task GIT_STATUS: :environment do
		g = git_open
		g.chdir do
			# fatal: ambiguous argument 'HEAD': unknown revision or path not in the working tree.
			# Use '--' to separate paths from revisions
			puts "#{g.status.each {}.length} git-related objects"
			# It is an Enumerable that returns Git:Status::StatusFile objects for each object in git,
			#  which includes files in the working directory, in the index and in the repository.
			# Similar to running 'git status' on the command line to determine untracked and changed files.
		end
	end

	# the git help
	desc "Version Control: Help"
	task HELP: :environment do

	end

	desc "Version Control: Show changed files"
	task GIT_CHANGED: :environment do
		g = git_open
		g.chdir do
			g.status.changed.each do |file|
				#binding.pry
				#puts file[1].blob(:index).contents
				puts file[0]
			end
		end
	end

	# must be chenged ?
	def record_em(git)
		git.chdir do
			changed = git.status.changed.collect{|x|x[0]}
			git.add(changed)
			vocal_commit(git,"#{changed.length} changes recorded")
		end
	end

	desc "Version Control: Show changed files"
	task GIT_RECORD: :environment do
		g = git_open
		record_em(g)
	end

	desc "Version Control: # of revisions, including on-disk change"
	task GIT_REV: :environment do
		g = git_open
		g.chdir do
			changed = []
			g.status.changed.each do |file|
				changed.push(file[0])
			end
			tracked = tracked_fyles(g).collect{|x|File.basename(x.local_file)}
			h = {}
			tracked.each do |t|
				i = g.follow(t)
				i += 1 if changed.include?(t)
				h[t] = i
			end
			p h
		end
	end

	desc "Version Control: Show diff"
	task :GIT_DIFF, [:file] => :environment do |t, args|
		g = git_open
		g.chdir do
			puts g.changed(args.file) # yeah, i know, it's got the same name as the command above
		end
	end

	# http://stackoverflow.com/questions/7147270/hard-reset-of-a-single-file
	desc "Version Control: Reset uncommited changes"
	task :GIT_RESET, [:file] => :environment do |t, args|
		g = git_open
		g.chdir do
			#g.reset
			begin
				g.uh(args.file)
			rescue Exception => e
				STDERR.puts "GIT_RESET #{e.class}"
				STDERR.puts e.message
			end
		end
	end

	desc "Version Control: Initialise"
	task GIT_INIT: :environment do
		require 'git'
		begin
			g = Git.init(corpus_folder)
			user_name = g.config('user.name')
			if 'Corpus Folder' == user_name
				STDOUT.puts "Repo re-initialised"
			else
				g.config('user.name', 'Corpus Folder')
				STDOUT.puts "Repo initialised"
				track_em(g)
			end
		rescue Exception => e
			STDERR.puts "GIT_INIT #{e.class}"
			STDERR.puts e.message
		end
	end

	desc "Version Control: Bare Initialise"
	task GIT_BARE: :environment do
		require 'git'
		begin
			g = Git.init(corpus_folder)
			user_name = g.config('user.name')
			if 'Corpus Folder' == user_name
				STDOUT.puts "Repo re-initialised"
			else
				g.config('user.name', 'Corpus Folder')
				STDOUT.puts "Bare repo initialised"
			end
		rescue Exception => e
			STDERR.puts "GIT_BARE #{e.class}"
			STDERR.puts e.message
		end
	end

	# standard git log
	# commit bd203660686245c9fa7ee1b3ba2c63ac7c0f91a4
	# Author: Corpus Folder <a.durity@umail.ucc.ie>
	# Date:   Sat Feb 25 15:08:56 2017 +0000
	#
	#     Freshly baked ~repo~
	desc "Version Control: Log list"
	task GIT_LOG: :environment do
		g = git_open
		g.log.each do |commit|
			puts "commit #{commit}"
			puts "Author: #{commit.author.name} <#{commit.author.email}>"
			puts "Date:   "+commit.date.strftime("%a %b %e %H:%M:%S %Y %z")
			# i don't know why "\n    "
			puts "\n    #{commit.message}"
		end
	end

	# need to fix email server and choose decent org email address
	desc "Version Control: Config list"
	task GIT_CONFIG: :environment do
		g = git_open
		g.config.each do |k,v|
			puts "#{k} => #{v}"
		end
	end

end

# Release the Monkey Patches!

module Git

	class Base

    def ls_file_name(path)
      self.lib.ls_file_name(path)
    end

		def changed(file)
			self.lib.changed(file)
		end

		def uh(file)
			self.lib.uh(file)
		end

		def follow(path)
			self.lib.follow(path)
		end

	end

	class Lib

		# http://stackoverflow.com/questions/2405305/how-to-tell-if-a-file-is-git-tracked-by-shell-exit-code
		# git ls-files file_name --error-unmatch
    def ls_file_name(path)
      command_lines('ls-files', [path, '--error-unmatch'])
    end

		def changed(file)
			if file.nil?
				command_lines('diff', ['-R'])
			else
				command_lines('diff', [file])
			end
		end

		def uh(file)
			if file.nil?
				reset_hard
			else
				command_lines('checkout', ['HEAD', '--', file])
			end
		end

		def follow(path)
			i = 0
			command_lines('log', ['--follow', path]).each do |line|
				i += 1 if line.start_with?('Date:')
			end
			i
		end
	end

end
