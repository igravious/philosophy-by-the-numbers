require "test_helper"
require "minitest/mock"
require "tmpdir"
require "git"
require_relative "../support/loaded_helpers"

class TheGitTest < ActiveSupport::TestCase
  include LoadedHelpers
  setup do
    @directory = Dir.mktmpdir
    @helper = load_helpers("lib/the_git.rb")
    @git = Git.init(@directory)
    @tracked = make_file("tracked.txt")
    @untracked = make_file("untracked.txt")
    @git.add(@tracked.local_file)
    @missing = Fyle.create!(what: "Missing", local_file: nil)
    @irregular = Fyle.create!(what: "Irregular", local_file: File.join(@directory, "absent.txt"))
    @files = Fyle.where(id: [@tracked.id, @untracked.id, @missing.id, @irregular.id])
  end

  teardown do
    FileUtils.remove_entry(@directory) if @directory
  end

  test "corpus path is relative to the configured Rails root" do
    assert_equal Rails.root.join(GlobalConstants::CORPUS_FOLDER).to_s, @helper.corpus_folder
  end

  test "opens the corpus Git repository with optional logging" do
    @helper.stub(:corpus_folder, @directory) do
      [true, false].each { |logging| assert_equal @directory, @helper.git_open(logging).dir.path }
    end
  end

  test "reports missing repository paths and unexpected open failures" do
    [ArgumentError.new("path does not exist"), ArgumentError.new("invalid repository"), IOError.new("unreadable")].each do |error|
      Git.stub(:open, ->(*) { raise error }) do
        capture_io { assert_raises(SystemExit) { @helper.git_open } }
      end
    end
  end

  test "file inventory counts missing irregular and regular files" do
    Fyle.stub(:all, @files) do
      totals = nil
      regular = nil
      output = capture_io { regular = @helper.the_fyles(true) { |*counts| totals = counts } }.first

      assert_equal [4, 1, 1], totals
      assert_equal [@tracked.id, @untracked.id].sort, regular.map(&:id).sort
      assert_includes output, "tracked.txt"
      assert_includes output, "absent.txt"
      assert_equal regular, @helper.the_fyles
    end
  end

  test "tracked and untracked selection reflect the actual Git index" do
    Fyle.stub(:all, @files) do
      assert_equal [@tracked.id], @helper.tracked_fyles(@git).map(&:id)
      assert_equal [@untracked.id], @helper.untracked_fyles(@git).map(&:id)
    end
  end

  test "unexpected Git errors are raised rather than misclassified as untracked files" do
    git = Object.new
    git.define_singleton_method(:ls_file_name) { |_| raise IOError, "failed index lookup" }
    Fyle.stub(:all, @files.where(id: @tracked.id)) do
      assert_raises(IOError) { @helper.tracked_fyles(git) }
      assert_raises(IOError) { @helper.untracked_fyles(git) }
    end
  end

  private

  def make_file(name)
    path = File.join(@directory, name)
    File.write(path, "Philosophical text")
    Fyle.create!(what: name, local_file: path)
  end
end
