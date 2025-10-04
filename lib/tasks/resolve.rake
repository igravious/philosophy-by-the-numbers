
def resolve_asset_paths(assets_directory)
	# Resolve relative paths in CSS
	Dir["#{assets_directory}/**/*.css"].each do |filename|
		p filename
		contents = File.read(filename) if FileTest.file?(filename)
		# http://www.w3.org/TR/CSS2/syndata.html#uri
		url_regex = /url\((?!\#)\s*['"]?(?![a-z]+:)([^'"\)]*)['"]?\s*\)/

		# Resolve paths in CSS file if it contains a url
		if contents =~ url_regex
			directory_path = Pathname.new(File.dirname(filename))
			.relative_path_from(Pathname.new(assets_directory))

			# Replace relative paths in URLs with Rails asset_path helper
			new_contents = contents.gsub(url_regex) do |match|
				relative_path = $1
				image_path = directory_path.join(relative_path).cleanpath
				puts "#{match} => #{image_path}"

				"url(<%= asset_path '#{image_path}' %>)"
			end

			# Replace CSS with ERB CSS file with resolved asset paths
			FileUtils.rm(filename)
			File.write(filename + '.erb', new_contents)
		end
	end
end

namespace :resolve do
	desc "Resolve assets paths in bower components"
	  task :paths, :relative_directory do |_, args|
			const = Rails.root.join('config', 'initializers', 'my_constants.rb')
			require const
			exit
			resolve_asset_paths(args[:relative_directory] || Rails.root.join('vendor', 'assets', GlobalConstants::BOWER_FOLDER))
		end
end
