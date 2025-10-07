Fyle.all.each do |f|
	begin
		str = f.snarf
		next if "#<RuntimeError: Not cached!>" == str
		str = str.force_encoding("UTF-8")
		hash = Digest::SHA256.hexdigest str
		f.health_hash = hash
		f.save!
	rescue StandardError => e
		STDERR.puts "Error processing file #{f.id}: #{e.message}"
		STDERR.puts e.backtrace.first
	end
end

