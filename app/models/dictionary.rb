class Dictionary < ActiveRecord::Base

	def domain
		self.URI.split('/')[2]
	end

	def content_title
		if self.content_uri.nil?
			self.title
		else
			self.title.gsub('Philosophy',"<a href=\"#{self.content_uri}\">Philosophy</a>")
		end
	end
end
