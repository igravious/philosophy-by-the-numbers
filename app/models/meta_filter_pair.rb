class MetaFilterPair < ActiveRecord::Base
	belongs_to :meta_filter

	# https://stackoverflow.com/questions/1906421/problem-saving-rails-marshal-in-sqlite3-db
	# https://stackoverflow.com/questions/6249456/uninitialized-constant-base64
	
	def value=(value)
		require 'base64'
		write_attribute :value, Base64.encode64(Marshal.dump(value))
	end

	def value
		require 'base64'
		begin
			Marshal.load(Base64.decode64(read_attribute :value))
		rescue
			# undefined method `unpack' for nil:NilClass
			nil
		end
	end
end
