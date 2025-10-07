ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

# Load thread error workarounds for Ruby 2.6.10 + Rails 4.2.11.3 compatibility
require_relative 'support/thread_error_workarounds'

# Ensure SecurityConfig is loaded for security tests
require Rails.root.join('app/lib/security_config')

check = "Checkpoint #{Time.now}"
ascii_line = '-'*check.size
Rails.logger.info ascii_line
Rails.logger.info check
Rails.logger.info ascii_line

Shadow.none

# Ensure danker directory structure exists for tests
danker_base = Rails.root.join('db', 'danker')
danker_dated = danker_base.join('2024-10-04')
danker_latest = danker_base.join('latest')

FileUtils.mkdir_p(danker_dated) unless danker_dated.exist?
unless danker_latest.exist? && danker_latest.symlink?
  FileUtils.rm_rf(danker_latest) if danker_latest.exist?
  FileUtils.ln_s(danker_dated, danker_latest)
end
# Create a dummy CSV file if it doesn't exist
csv_file = danker_dated.join('test.csv')
File.write(csv_file, "Q1,0.5\n") unless csv_file.exist?

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
