# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

# Suppress common deprecation warnings
ENV['RUBYOPT'] = "#{ENV['RUBYOPT']} -W0" unless ENV['RUBYOPT']&.include?('-W0')

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
