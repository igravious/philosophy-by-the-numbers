class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

	before_filter :set_correct_host_and_relative_root

	def set_correct_host_and_relative_root
		# do once?
		# https://stackoverflow.com/questions/7154914/how-to-get-host-name-in-rails-3
		# mailer?
		Rails.application.routes.default_url_options[:host] = request.host_with_port+Rails.application.config.relative_url_root
	end
end
