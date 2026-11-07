require "test_helper"
require "minitest/mock"
require "tmpdir"
require "stringio"
require "knowledge"
require_relative "../support/rake_task_testing"

class ReferenceIndexTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  Entry = Struct.new(:text, :href, :title, :name, :parent) do
    def a
      self
    end

    def wait_until_present(*)
      self
    end
  end

  List = Struct.new(:lis) do
    def wait_until_present(*)
      self
    end
  end

  setup do
    @directory = Dir.mktmpdir("reference-indices-")
    use_rake_tasks(Rails.root.join("lib/tasks/snarf.rake"))
    @receiver = Rake::Task["snarf:sep"].actions.first.binding.receiver
    @urls = []
    @closed = []
    @started = []
    @headless = Object.new
    started = @started
    @headless.define_singleton_method(:start) { started << true }
    @headless.define_singleton_method(:destroy) { true }
    [1, 2, 3, 4, 5, 8, 9, 12].each do |id|
      dictionary = Dictionary.find_by(id: id) || Dictionary.new(id: id, title: "Reference #{id}")
      dictionary.URI = "https://reference.test/index.htm"
      dictionary.save!
    end
  end

  teardown do
    restore_rake_tasks
    FileUtils.remove_entry(@directory)
  end

  test "Stanford index output keeps nonblank entries from its content section" do
    content = Struct.new(:id).new("content")
    other = Struct.new(:id).new("other")
    entries = [Entry.new("First\nSecond", nil, nil, nil, Struct.new(:parent).new(content)),
      Entry.new("", nil, nil, nil, Struct.new(:parent).new(content)),
      Entry.new("Ignored", nil, nil, nil, Struct.new(:parent).new(other))]
    with_browsers(-> { browser(lis: -> { entries }) }) do
      output = run_task("sep")
      assert_equal "First\n  Second\n", output
    end
    assert_equal 1, @started.size
    assert_equal 1, @closed.size
  end

  test "Runes index extracts named anchors across alphabetic pages" do
    entries = [Entry.new(nil, nil, nil, "Aristotle"), Entry.new(nil, nil, nil, "")]
    with_browsers(-> { browser(as: -> { entries }) }) do
      assert_equal 26, run_task("runes").lines.count { |line| line.strip == "Aristotle" }
    end
    assert_equal 26, @closed.size
    assert @urls.first.end_with?("/a.html")
    assert @urls.last.end_with?("/z.html")
  end

  test "Routledge index handles linked headings and plain heading fallbacks" do
    linked = Entry.new("Linked heading")
    fallback = Object.new
    fallback.define_singleton_method(:a) { raise NoMethodError, "no link" }
    fallback.define_singleton_method(:text) { "Plain heading" }
    with_browsers(-> { browser(h4s: ->(*) { [linked, fallback] }) }) do
      output = run_task("rep")
      assert_equal 144, output.lines.count { |line| line.strip == "Linked heading" }
      assert_equal 144, output.lines.count { |line| line.strip == "Plain heading" }
    end
    assert_equal 144, @closed.size
  end

  test "Internet encyclopedia index marks nested entries" do
    ordinary_parent = Struct.new(:parent).new(Object.new)
    nested_parent = Struct.new(:parent).new(Watir::LI.allocate)
    entries = [Entry.new(nil, nil, "Primary entry", nil, ordinary_parent), Entry.new(nil, nil, "Nested entry", nil, nested_parent)]
    with_browsers(-> { browser(ul: ->(*) { List.new(entries) }) }) do
      output = run_task("iep")
      assert_equal 26, output.lines.count { |line| line.strip == "Primary entry" }
      assert_equal 26, output.lines.count { |line| line.strip == "- Nested entry" }
    end
    assert_equal 26, @closed.size
  end

  test "Oxford second edition index visits all pages and extracts item headings" do
    with_browsers(-> { browser(h2s: ->(*) { [Entry.new("Example Figure (1700–1780)")] }) }) do
      assert_equal 34, run_task("odp_2nd").lines.size
    end
    refute_includes @urls.first, "&page=1&"
    assert_includes @urls.last, "&page=34&"
    assert_equal 34, @closed.size
  end

  test "Oxford third edition index expands nonstandard dates from the entry headword" do
    factory = -> do
      browser(h2s: ->(*) { [Entry.new("Normal Figure (1700–1780)"), Entry.new("Ancient Figure (400 BC)", "https://reference.test/ancient")] },
        span: ->(*) { Entry.new("Ancient Figure (470–399 BCE).") })
    end
    with_browsers(factory) do
      output = run_task("odp_3rd")
      assert_equal 7, output.lines.count { |line| line.strip == "Ancient Figure (470–399 BCE)" }
      assert_equal 7, output.lines.count { |line| line.strip == "Normal Figure (1700–1780)" }
    end
    assert @urls.any? { |url| url == "https://reference.test/ancient" }
  end

  test "InPhO index reports an empty index without making detail requests" do
    requests = []
    open_page = ->(url, &block) {
      requests << url
      block.call(StringIO.new("<div id='content'><ul></ul></div>"))
    }
    @receiver.stub(:open, open_page) do
      assert_includes run_task("inpho"), "Could not find any thinkers"
    end
    assert_equal ["https://www.inphoproject.org/thinker"], requests
  end

  test "InPhO metadata resolves a Wikidata identity and persists BCE years in delegated attributes" do
    index = "<div id='content'><ul><li><a href='/thinker/1234'>Example Thinker</a></li></ul></div>"
    details = "<dl><dt>Birth Dates:</dt><dd>470 B.C.E.</dd><dt>Death Dates:</dt><dd>399 B.C.E.</dd><dt>Nationality/ethnicity:</dt><dd>Greek</dd></dl>" \
      "<h1 data-id='1234'>Example Thinker</h1><p><a href='http://wikipedia.org/wiki/Example_Thinker'>Wikipedia</a></p>"
    open_page = ->(url, &block) { block.call(StringIO.new(url.end_with?("/thinker") ? index : details)) }
    @receiver.stub(:open, open_page) do
      Knowledge::Wikipedia::API.stub(:wikibase_item, "Q7654321") do
        Dir.chdir(@directory) { run_task("inpho") }
      rescue SystemExit
        flunk "The metadata task must complete its import instead of exiting after the first lookup"
      end
    end
    figure = Philosopher.find_by!(entity_id: 7_654_321)
    assert_equal 1234, figure.inpho
    assert_equal(-470, figure.birth_year)
    assert_equal(-399, figure.death_year)
    assert_equal "Example Thinker", JSON.parse(File.read(File.join(@directory, "inpho.json"))).first["name"]
  end

  private

  def browser(methods = {})
    instance = Object.new
    urls = @urls
    closed = @closed
    instance.define_singleton_method(:goto) { |url| urls << url }
    instance.define_singleton_method(:quit) { closed << true }
    instance.define_singleton_method(:close) { closed << true }
    methods.each { |name, implementation| instance.define_singleton_method(name, implementation) }
    instance
  end

  def with_browsers(factory, &block)
    Headless.stub(:new, @headless) { Watir::Browser.stub(:new, factory, &block) }
  end

  def run_task(name)
    task = Rake::Task["snarf:#{name}"]
    task.reenable
    capture_io { task.invoke }.first
  end
end
