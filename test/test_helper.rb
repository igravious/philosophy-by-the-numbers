# SimpleCov must be loaded FIRST before any application code
if ENV['COVERAGE']
  require 'simplecov'
end

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

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Map plural model names to their classes for fixture loading
  set_fixture_class canonicity_weights: CanonicityWeights

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Create a test philosopher with sensible defaults.
  # Use this instead of philosopher fixtures (STI fixture loading is unreliable).
  def create_test_philosopher(attrs = {})
    defaults = {
      entity_id: 900_000 + rand(99_999),
      mention: 1,
      danker: 0.5,
      measure: 0.5
    }
    Philosopher.create!(defaults.merge(attrs))
  end

  # Create a test work with sensible defaults.
  def create_test_work(attrs = {})
    defaults = {
      entity_id: 800_000 + rand(99_999),
      mention: 1,
      danker: 0.3,
      measure: 0.3
    }
    Work.create!(defaults.merge(attrs))
  end
end

class ActionController::TestCase
  include Rails.application.routes.url_helpers
end
