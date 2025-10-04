#!/usr/bin/env ruby
require 'pathname'

# Load .gitignore patterns
gitignore_file = Pathname.new(".gitignore")
patterns = []
if gitignore_file.exist?
  gitignore_file.read.each_line do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")
    patterns << line
  end
end

# Check if a path is ignored according to patterns
def ignored?(path, patterns)
  path = path.gsub("\\", "/") # normalize
  ignore = false
  patterns.each do |pattern|
    negated = pattern.start_with?("!")
    pat = negated ? pattern[1..] : pattern

    # Convert gitignore pattern to glob
    glob = pat
    glob = glob.sub(%r{^\./}, '') # remove leading ./
    
    # Use File.fnmatch with FNM_PATHNAME
    if File.fnmatch?(glob, path, File::FNM_PATHNAME | File::FNM_DOTMATCH)
      ignore = !negated
    end
  end
  ignore
end

# Traverse all files recursively
file_sizes = []
Dir.glob("**/*", File::FNM_DOTMATCH).each do |f|
  next if File.directory?(f)
  next if ignored?(f, patterns)
  begin
    file_sizes << [File.size(f), f]
  rescue
    next
  end
end

# Top 20 largest
top20 = file_sizes.sort_by { |size, _| -size }.first(20)

puts "Top 20 largest files (size in bytes):"
top20.each do |size, path|
  puts "%10d  %s" % [size, path]
end

