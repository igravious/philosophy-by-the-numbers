# require 'rails/application_controller'

# class Rails::InfoController < Rails::ApplicationController # :nodoc:
class InfoController < ApplicationController # :nodoc:
  layout -> { request.xhr? ? false : 'application' } # how?

  def schema
    @schema = 'yo!'
    @page_title = 'Schema'
		render :layout => false
  end
end
