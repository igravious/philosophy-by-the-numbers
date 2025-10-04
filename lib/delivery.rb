
	class Delivery
		include ActiveModel::Model
		attr_accessor :identifier, :location, :date
		attr_accessor :numbered, :amount, :play

		def consistent
			require 'base64'
			require 'digest/sha1'

			Digest::SHA1.hexdigest(Base64.encode64(@identifier)+Base64.encode64(@location)+Base64.encode64(@date))
		end

		# http://www.nsftools.com/tips/HexWords.htm
		# https://en.wikipedia.org/wiki/Fabaceae
		SEED = 0xfabaceae
		# r = Random.new(SEED)
		# r.rand(256)
	end

