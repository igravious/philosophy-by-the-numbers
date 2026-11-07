#!/usr/bin/env ruby

require 'open3'

# Run rake -T and capture output
stdout, stderr, status = Open3.capture3('bin/rake -T')

if status.success?
  # Parse tasks from output (format: "rake task_name[args]                            # description")
  tasks = stdout.lines.map(&:strip).reject(&:empty?).map do |line|
    # Extract task name and description
    if line =~ /^rake\s+([^\s\[\#]+)(?:\[[^\]]*\])?\s*#?\s*(.*)$/
      task = $1
      desc = $2.strip.empty? ? "..." : $2.strip
      [task, desc]
    else
      nil
    end
  end.compact

  # Known built-in namespaces (common Rails/Rake prefixes)
  builtin_namespaces = %w[db: assets: test: log: tmp: rails: time: cache_digests: doc: about routes secret stats notes middleware test]

  custom_tasks = []
  builtin_tasks = []

  tasks.each do |task, desc|
    if builtin_namespaces.any? { |ns| task.start_with?(ns) }
      builtin_tasks << [task, desc]
    else
      custom_tasks << [task, desc]
    end
  end

  puts "BUILT-IN TASKS (#{builtin_tasks.size}):"
  builtin_tasks.sort_by(&:first).each { |task, desc| puts "  #{task} - #{desc}" }

  puts "\nUSER-CREATED TASKS (#{custom_tasks.size}):"
  custom_tasks.sort_by(&:first).each { |task, desc| puts "  #{task} - #{desc}" }

  # Summary count
  puts "\n" + "=" * 50
  puts "SUMMARY: #{builtin_tasks.size + custom_tasks.size} total tasks"
  puts "  Built-in: #{builtin_tasks.size} tasks"
  puts "  User-created: #{custom_tasks.size} tasks"
  puts "=" * 50
else
  puts "Error running rake -T: #{stderr}"
end