# This file is used by Rack-based servers to start the application.

# https://stackoverflow.com/questions/7190015/how-do-i-get-a-list-of-files-that-have-been-required-in-ruby
$_REQ=[]
alias :orig_require :require
def require s
  # print "Requires #{s}\n" if orig_require(s)
  $_REQ.push(s) if orig_require(s)
end

module Kernel
  def self.required(list)
    list.
      select { |feature| feature.include? 'gems' }.
      map { |feature| File.dirname(feature) }.
      map { |feature| feature.split('/').last }.
      uniq.sort
  end
end

# OK, quit messing around

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application

=begin
App Configuration Constants (YAML format):
---
RELATIVE_URL_ROOT: ''
ASSETS_VERSION: '1.0'
CACHE_NAMESPACE_DEV: 'CORPUS_DEV_V1'
CACHE_NAMESPACE_PROD: 'CORPUS_PROD_V1'
LOG_LEVEL_PROD: 'info'
=end
