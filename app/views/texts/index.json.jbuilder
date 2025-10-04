
Rails.logger.info(local_variables)

@files = Fyle.all
# @papers = []
# @files.each do |file|
json.array!(@files) do |file|
	text = file.text
	if !text.nil?
		if !text.include
			next
		end
		json.extract! text, :id, :name_in_english, :original_year, :edition_year
		# json.url plain_fyle_path(file, format: :json)
		json.url plain_fyle_path(id: file.id.to_s.rjust(3, "0"), format: 'txt')
	end
end
