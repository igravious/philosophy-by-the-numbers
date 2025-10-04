require File.expand_path('../boot', __FILE__)

require 'rails/all' # what does this load?

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CorpusBuilder
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Suppress common deprecation warnings
    config.active_support.deprecation = :silence if Rails.env.development? || Rails.env.test?

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
	
		# config.middleware.insert(0, Rack::Deflater)	
		# config.web_console.whitelisted_ips = '109.125.16.43'
		# config.web_console.whiny_requests = false
		
		config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components')

		# http://stackoverflow.com/questions/9927630/ruby-on-rails-log-file-to-big-remove-params-from-it
		config.filter_parameters += [:content]

	  console do
	    require 'console_extension' # lib/console_extension.rb
	    Rails::ConsoleMethods.send :include, ConsoleExtension::ConsoleHelpers
	    Rails::ConsoleMethods.send :extend, ConsoleExtension::ConsoleMethods
	  end
  end
end
