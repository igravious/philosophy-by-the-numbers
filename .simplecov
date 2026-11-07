require "simplecov-console"

SimpleCov.start do
  subprocess = ENV["CORPUS_COVERAGE_SUBPROCESS"] == "1"
  track_files "{app/**/*.rb,lib/**/*.{rb,rake},config/**/*.rb,scripts/**/*.rb,bin/{bundle,corpus,rails,rake,setup},Rakefile,config.ru}" unless subprocess
  add_filter "/test/"
  add_filter "/vendor/"
  add_filter "/db/"
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Helpers", "app/helpers"
  add_group "Application Libraries", "app/lib"
  add_group "Libraries", "lib"
  add_group "Rake Tasks", "lib/tasks"
  add_group "Scripts", "scripts"
  add_group "Runtime Configuration", "config"
  required_coverage = subprocess ? 0 : 100
  minimum_coverage required_coverage
  minimum_coverage_by_file required_coverage
  merge_timeout 3600
  SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::Console]
end
