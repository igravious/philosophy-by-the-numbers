ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

# Load thread error workarounds for Ruby 2.6.10 + Rails 4.2.11.3 compatibility
require_relative 'support/thread_error_workarounds'

check = "Checkpoint #{Time.now}"
ascii_line = '-'*check.size
Rails.logger.info ascii_line
Rails.logger.info check
Rails.logger.info ascii_line

Shadow.none

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # Fixtures disabled - most tests create their own data or use mocks
  # fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionController::TestCase
  include Rails.application.routes.url_helpers
end
