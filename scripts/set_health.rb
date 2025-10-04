Fyle.all.each do |f|
	begin
		str = f.snarf
		next if "#<RuntimeError: Not cached!>" == str
		str = str.force_encoding("UTF-8")
		hash = Digest::SHA256.hexdigest str
		f.health_hash = hash
		f.save!
	rescue
		binding.pry
	end
end

