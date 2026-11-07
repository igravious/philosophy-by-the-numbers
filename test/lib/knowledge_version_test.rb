require 'test_helper'
require 'knowledge/version'

class KnowledgeVersionTest < ActiveSupport::TestCase
  test "VERSION constant is defined" do
    assert_equal '0.0.1', Knowledge::VERSION
  end

  test "VersionInfo class exists" do
    assert defined?(Knowledge::VersionInfo)
  end
end
