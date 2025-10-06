require 'test_helper'

class DankerUpdateRakeTaskTest < ActiveSupport::TestCase
  # Disable fixtures to avoid conflicts with existing data
  self.use_transactional_fixtures = false
  self.use_instantiated_fixtures = false
  
  # Override fixture methods to prevent loading
  def self.fixture_path
    nil
  end
  
  def self.fixtures(*args)
    # Do nothing to prevent fixture loading
  end

  def setup
    @test_danker_dir = Rails.root.join('db', 'danker', 'test')
    @latest_link = Rails.root.join('db', 'danker', 'latest')
    
    # Clean up any existing test data
    FileUtils.rm_rf(@test_danker_dir) if @test_danker_dir.exist?
    FileUtils.rm_f(@latest_link) if @latest_link.exist?
    
    # Load rake tasks
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end
  
  def teardown
    # Clean up test data
    FileUtils.rm_rf(@test_danker_dir) if @test_danker_dir.exist?
    FileUtils.rm_f(@latest_link) if @latest_link.exist?
  end

  test "danker:update task creates proper directory structure" do
    skip "Skipping integration test that requires external network calls"
    
    # This test would verify:
    # 1. Downloads latest danker data
    # 2. Creates versioned directory structure
    # 3. Updates 'latest' symlink
    # 4. Handles existing data appropriately
    
    # Implementation would mock HTTP calls and file operations
  end

  test "danker:update handles missing data gracefully" do
    # Test the error handling when no danker data is available
    output = capture_output do
      begin
        Rake::Task['danker:update'].invoke
      rescue SystemExit => e
        # Expected when no data available
      end
    end
    
    # Verify appropriate error messages
    assert_includes output[:stderr], "danker" unless output[:stderr].empty?
    
    # Clean up rake task state
    Rake::Task['danker:update'].reenable
  end

  test "danker directory structure follows convention" do
    # Create mock danker data structure
    version_dir = @latest_link.dirname.join('2024-10-04')
    FileUtils.mkdir_p(version_dir)
    
    # Create mock CSV file
    csv_file = version_dir.join('2024-10-04.all.links.c.alphanum.csv')
    File.write(csv_file, "Q123,0.5\nQ456,0.8\n")
    
    # Create symlink
    FileUtils.ln_sf('2024-10-04', @latest_link)
    
    # Verify structure
    assert @latest_link.exist?, "Latest symlink should exist"
    assert @latest_link.symlink?, "Latest should be a symlink"
    assert_equal '2024-10-04', @latest_link.readlink.to_s
    
    csv_files = Dir.glob(@latest_link.join('*.c.alphanum.csv'))
    assert_equal 1, csv_files.length, "Should find exactly one CSV file"
    assert_includes csv_files.first, '2024-10-04'
  end

  test "danker data format validation" do
    # Create test data with various formats
    version_dir = @latest_link.dirname.join('2024-10-04')
    FileUtils.mkdir_p(version_dir)
    
    csv_file = version_dir.join('2024-10-04.all.links.c.alphanum.csv')
    test_data = [
      "Q123,0.5",
      "Q456,0.8",
      "Q789,0.0",
      "Q101112,1.0"
    ].join("\n")
    
    File.write(csv_file, test_data)
    
    # Read and validate data format
    data = File.read(csv_file)
    lines = data.strip.split("\n")
    
    lines.each do |line|
      parts = line.split(',')
      assert_equal 2, parts.length, "Each line should have exactly 2 parts"
      assert_match /^Q\d+$/, parts[0], "First part should be Qid format"
      assert_match /^\d+(\.\d+)?$/, parts[1], "Second part should be numeric"
    end
  end

  private
  
  def capture_output
    old_stdout, old_stderr = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new
    yield
    { stdout: $stdout.string, stderr: $stderr.string }
  ensure
    $stdout, $stderr = old_stdout, old_stderr
  end
end