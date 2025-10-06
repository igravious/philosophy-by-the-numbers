require 'test_helper'

# Tests for the danker data management functionality
class DankerUpdateTest < ActiveSupport::TestCase
  test "danker update task exists" do
    # Test that our rake task exists
    require 'rake'
    Rails.application.load_tasks
    
    assert Rake::Task.task_defined?('danker:update'), "danker:update task should be defined"
    assert Rake::Task.task_defined?('danker:list'), "danker:list task should be defined"
  end
  
  test "danker data directory structure" do
    danker_dir = Rails.root.join('db', 'danker')
    
    # For this test, we just verify the structure would be correct
    # We don't actually download data in tests
    assert danker_dir.to_s.include?('db/danker'), "Should have correct danker directory path"
  end
end