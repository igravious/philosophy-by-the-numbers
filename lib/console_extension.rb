# lib/console_extension.rb
module ConsoleExtension
  # This module provides methods that are only available in the console
  module ConsoleHelpers
    def start_up
      Shadow.none
			Shadow.connection.nil?
    end
  end

  # This is a simple class that allows us access to the ConsoleHelpers before
  # we get into the console
  class ConsoleRunner
    include ConsoleExtension::ConsoleHelpers
  end

  # This is specifically to patch into the startup behavior for the console.
  #
  # In the console_command.rb file, it does this right before start:
  #
  # if defined?(console::ExtendCommandBundle)
  #   console::ExtendCommandBundle.include(Rails::ConsoleMethods)
  # end
  #
  # This is a little tricky. We're defining an included method on this module
  # so that the Rails::ConsoleMethods module gets a self.included method.
  #
  # This causes the Rails::ConsoleMethods to run this code when it's included
  # in the console::ExtendCommandBundle at the last step before the console
  # starts, instead of during the earlier load_console stage.
  module ConsoleMethods
    def included(_klass)
      ConsoleExtension::ConsoleRunner.new.start_up
    end
  end
end
