require "bundler/setup"
ENV["CORPUS_COVERAGE_SUBPROCESS"] = "1"
require "simplecov"

SimpleCov.command_name "Subprocess #{Process.pid}"
SimpleCov.formatters = []

if __FILE__ == $PROGRAM_NAME
  $PROGRAM_NAME = File.expand_path(ARGV.shift)
  load $PROGRAM_NAME
end
