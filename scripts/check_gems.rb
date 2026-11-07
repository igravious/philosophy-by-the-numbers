#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'set'

def run_cmd(*cmd)
	stdout, stderr, status = Open3.capture3(*cmd)
	# raise "#{cmd.join(' ')} failed:\n#{stderr}" unless status.success?
	stdout
end

puts 'Running bin/bundle list --name-only…'
list_output = run_cmd('bin/bundle', 'list', '--name-only')
listed = list_output.lines.map(&:strip).reject(&:empty?).to_set
# p listed

puts 'Running bin/bundle outdated…'
outdated_output = run_cmd('bin/bundle', 'outdated')
outdated = outdated_output.lines.each_with_object(Set.new) do |line, acc|
	line = line.strip
	next unless line.start_with?('* ') || line.start_with?('  * ')
	parts = line.split
	acc << parts[1] if parts[1]
end
# p outdated

missing = listed - outdated

if missing.empty?
	puts 'Every gem from `bin/bundle list --name-only` also appears in `bin/bundle outdated`.'
else
	puts 'Gems missing from `bin/bundle outdated`:'
	missing.sort.each { |gem_name| puts "  - #{gem_name}" }
end
