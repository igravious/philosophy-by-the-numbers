#!/usr/bin/env ruby

# Get all rake tasks
all_tasks_output = `bin/rake -T`
all_tasks = all_tasks_output.split("\n").map do |line|
  line.split("#").first.strip.split("rake ").last
end.compact

# Define built-in namespaces (Rails and standard rake tasks)
built_in_namespaces = %w[
  about assets cache_digests db doc log middleware notes rails routes secret stats test time tmp
]

# Categorize tasks
built_in_tasks = []
user_created_tasks = []

all_tasks.each do |task|
  namespace = task.split(':').first
  if built_in_namespaces.include?(namespace) || !task.include?(':')
    built_in_tasks << task
  else
    user_created_tasks << task
  end
end

# Sort tasks
built_in_tasks.sort!
user_created_tasks.sort!

# Print results
puts "BUILT-IN TASKS (#{built_in_tasks.size}):"
built_in_tasks.each { |t| puts "  #{t}" }

puts "\nUSER-CREATED TASKS (#{user_created_tasks.size}):"
user_created_tasks.each { |t| puts "  #{t}" }

# Summary count
puts "\n" + "=" * 50
puts "SUMMARY: #{built_in_tasks.size + user_created_tasks.size} total tasks"
puts "  Built-in: #{built_in_tasks.size} tasks"
puts "  User-created: #{user_created_tasks.size} tasks"
puts "=" * 50