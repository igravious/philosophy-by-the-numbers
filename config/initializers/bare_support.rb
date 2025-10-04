
# A Ruby on Rails application loads all Active Support unless config.active_support.bare is true.
CorpusBuilder::Application.config.active_support.bare

require 'active_support/core_ext/object/blank'
