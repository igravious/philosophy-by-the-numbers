
	def corpus_folder
		Rails.root.join(GlobalConstants::CORPUS_FOLDER).to_path
	end

	def git_open(log=false)
		require 'git'
		begin
			if log
				g = Git.open(corpus_folder, :log => Logger.new(STDOUT))
			else
				g = Git.open(corpus_folder)
			end
		rescue ArgumentError => e
			if 'path does not exist' == e.message
				STDOUT.puts 'Possibly uninitialised repo'
			else
				STDERR.puts "Some kind of unexpected argument error in git_open"
				STDERR.puts e.message
			end
			exit
		rescue Exception => e
			STDERR.puts "Some kind of exception in git_open"
			STDERR.puts e.message
			exit
		end
	end

	def the_fyles(noisy=false)
		irregular = 0
		missing = 0
		regular = []
		total = Fyle.all.each do |f|
			id = '['+sprintf("%06d",f.id)+']' if noisy
			if f.local_file.blank?
				missing += 1
				mark = '?' if noisy
			else
				if File.file?(f.local_file)
					mark = "✓ #{f.local_file}" if noisy
					regular.push(f)
				else
					mark = "✗ #{f.local_file}" if noisy
					irregular += 1
				end
			end
			puts "#{id} #{mark}" if noisy
		end.length
		yield total, missing, irregular if block_given?
		regular
	end

	def untracked_fyles(git)
		untracked = []
		total = Fyle.all.each do |f|
			if not f.local_file.blank?
				if File.file?(f.local_file)
					begin
						res = git.ls_file_name(f.local_file)
					rescue Git::GitExecuteError => expected
						untracked.push(f)
					rescue Exception => unexpected
						# don't need to do this, could just leave it unhandled
						raise unexpected		
					end
				end
			end
		end.length
		untracked
	end

	def tracked_fyles(git)
		tracked = []
		total = Fyle.all.each do |f|
			if not f.local_file.blank?
				if File.file?(f.local_file)
					begin
						res = git.ls_file_name(f.local_file)
						tracked.push(f)
					rescue Git::GitExecuteError => expected
						nil
					rescue Exception => unexpected
						# don't need to do this, could just leave it unhandled
						raise unexpected		
					end
				end
			end
		end.length
		tracked
	end
