
	require 'elasticsearch'

	# NOTE: This helper was written for older Elasticsearch without security.
	# Modern ES requires HTTPS + authentication. To fix:
	# Elasticsearch::Client.new(
	#   url: 'https://localhost:9200',
	#   user: 'elastic',
	#   password: 'your_password',
	#   transport_options: { ssl: { verify: false } }
	# )

	def elastic(log_switch)
		begin
			name = caller[0]
			# STDOUT.puts "called from #{name}"
			ec = Elasticsearch::Client.new log: log_switch
			Rails.logger.info ec.inspect
		rescue Exception => msg
			Rails.logger.error "  Possible Elastic Search issue? #{msg}"
			ec = nil
			# STDERR.puts juju
		end
		yield ec
	end

	def count_snaps
		query = Elasticsearch::Client.new log: false
		Rails.logger.info query.inspect
		begin
			res = query.get(index: 'corpus', type: 'snapshots', id: 0) {}
			Rails.logger.info res.inspect
			counter = res['_source']['counter']
			return counter.to_i
		rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
			return 0
		end
	end

	def latest_snap
		# TODO if 0 blah
		'snapshot'+(count_snaps.to_s)
	end

