# Suppress Ruby warnings to reduce noise from deprecation messages
# This is shared across bin/bundle, bin/rails, and bin/rake

$VERBOSE = nil

# Also set environment variable for any subprocesses
ENV['RUBYOPT'] = "#{ENV['RUBYOPT']} -W0" unless ENV['RUBYOPT']&.include?('-W0')