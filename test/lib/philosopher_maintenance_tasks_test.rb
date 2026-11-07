require "test_helper"
require "minitest/mock"
require "tmpdir"
require "timeout"
require_relative "../support/rake_task_testing"
require_relative "../../lib/wikidata/query_executor"

class PhilosopherMaintenanceTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting

  setup do
    use_rake_tasks(Rails.root.join("lib/tasks/shadow.rake"))
    @receiver = Rake::Task["shadow:philosopher:help"].actions.first.binding.receiver
    @directory = Dir.mktmpdir("philosopher-tasks-")
    FileUtils.mkdir_p(File.join(@directory, "log"))
    @debug = ENV["SPARQL_DEBUG"]
    @figure = create_test_philosopher(measure: 2.0, mention: 0, linkcount: 0, populate: false, stanford: true)
    @figure.names.create!(lang: "en", label: "Coverage Figure")
    @other = create_test_philosopher(measure: 1.0, mention: 1, linkcount: nil, populate: true, birth: "1724", death: "1804")
    @other.names.create!(lang: "en", label: "Other Figure")
  end

  teardown do
    ENV["SPARQL_DEBUG"] = @debug
    restore_rake_tasks
    FileUtils.remove_entry(@directory)
  end

  test "selection presets query canonical and delegated metadata columns" do
    presets = %w[ranked philosophers works pagerank_n metric_n measure_n mention_z linkcount_z linkcount_n linkcount_n_z birth_n death_n extra c_today u_today c_hour u_hour]
    presets.each do |preset|
      relation = @receiver.send(:select, preset)
      assert relation.respond_to?(:to_a), preset
      relation.to_a
    end
    assert_includes @receiver.send(:select, "birth_n"), @figure
    refute_includes @receiver.send(:select, "birth_n"), @other
    assert_includes @receiver.send(:select, "stanford"), @figure
    refute_includes @receiver.send(:select, "extra"), @other
    assert_equal [@figure.id], @receiver.send(:select, "Q#{@figure.entity_id}").pluck(:id)
    assert_equal [@figure.id], @receiver.send(:select, @figure.id.to_s).pluck(:id)
    assert_nil @receiver.send(:select, "not_a_column")
    capture_io { assert_nil @receiver.send(:select, nil) }
  end

  test "property selections preserve unique referenced entities and redirect identity rules" do
    P::P27.create!(entity_id: @figure.entity_id, redirect_id: @figure.entity_id, object_id: 145, object_label: "Country")
    P::P27.create!(entity_id: @other.entity_id, redirect_id: 999, object_id: 84, object_label: "Redirect")
    P::D1.create!(entity_id: @figure.entity_id, redirect_id: @figure.entity_id, object_id: 145, object_label: "School")
    assert_equal [145], @receiver.send(:select, "P27").map(&:entity_id)
    assert_equal [145], @receiver.send(:select, "D1").map(&:entity_id)
  end

  test "date normalization handles single dates discarded placeholders nearby alternatives and approximations" do
    cases = {
      nil => [nil, nil], "1724" => ["1724", nil], "t123;1724" => ["1724", nil],
      "t123;t456" => [nil, nil], "1724;1724" => ["1724", nil],
      "1724;1700" => ["1700;1724", nil], "1700;1724" => ["1700;1724", nil],
      "1500;1800" => [nil, nil], "invalid;also invalid" => [nil, nil],
      "1700;1800;1900" => [1800, true]
    }
    cases.each do |value, expected|
      attributes = {births: value}
      capture_io { @receiver.send(:do_date, "Q42", attributes, :birth) }
      assert_equal expected, [attributes[:birth], attributes[:birth_approx]], value.inspect
      refute attributes.key?(:births)
    end
    assert_equal({birth: "1724", death: "1804"}, @receiver.send(:birth_death, "Q42", {births: "1724", deaths: "1804"}))
  end

  test "date comparisons allow exact and adjacent years and reject incompatible or unknown proposals" do
    [[1724, 1804], [1724, 1803], [1724, 1805], [1723, 1804], [1725, 1804]].each do |birth, death|
      assert @receiver.send(:check_date, @other, birth, death)
    end
    refute @receiver.send(:check_date, @other, 1800, 1900)
    refute @receiver.send(:check_date, @figure, 1724, 1804)
    assert_equal " (1724/1804)", @receiver.send(:make_append, @other)
    assert_equal " (/)", @receiver.send(:make_append, @figure)
  end

  test "translation queries keep language tags and use legal variable names" do
    %i[xlate xlate2].each do |method|
      query = @receiver.send(method, "Q42", %w[en zh-tw])
      assert_includes query, "?zh_twLabel"
      assert_includes query, "zh-tw"
      assert_includes query, "wd:Q42"
      assert_includes query, "GROUP BY"
    end
  end

  test "query and operation logs record exact queries and tolerate unwritable destinations" do
    ENV["SPARQL_DEBUG"] = "true"
    Rails.stub(:root, Pathname.new(@directory)) do
      output = capture_io do
        @receiver.send(:log_sparql_query, "SELECT\t?item", "maintenance", entity: "Q42")
        @receiver.send(:log_task_output, "Operation completed")
      end.first
      assert_includes output, "SELECT  ?item"
      log = File.read(File.join(@directory, "log/sparql_queries.log"))
      assert_includes log, "maintenance"
      assert_includes log, "Operation completed"
    end
    Rails.stub(:root, Pathname.new(File.join(@directory, "missing"))) do
      output = capture_io do
        @receiver.send(:log_sparql_query, "SELECT", "missing")
        @receiver.send(:log_task_output, "missing")
      end.first
      assert_includes output, "SPARQL logging failed"
      assert_includes output, "Task logging failed"
    end
  end

  test "population preview leaves the database unchanged and explicit force creates missing identities" do
    rows = solutions({entity: entity(@figure.entity_id), entityLabel: RDF::Literal.new("Existing", language: :en)},
      {entity: entity(7_654_320), entityLabel: RDF::Literal.new("New", language: :en)},
      {entity: entity(7_654_321), entityLabel: RDF::Literal.new("Unlocalized")})
    with_progress do
      Wikidata::QueryExecutor.stub(:execute_philosopher_query, rows) do
        assert_no_difference("Philosopher.count") { run_task("populate") }
        assert_difference("Philosopher.count", 2) { run_task("populate", "true") }
      end
    end
    assert Philosopher.find_by!(entity_id: 7_654_320).populate
    assert Philosopher.find_by!(entity_id: 7_654_321).populate
  end

  test "population failures are reported without creating partial identities" do
    errors = []
    rows = solutions(entity: RDF::URI("http://www.wikidata.org/entity/invalid"), entityLabel: RDF::Literal.new("Invalid"))
    @receiver.stub(:barf, ->(error, context) { errors << [error, context] }) do
      with_progress do
        Wikidata::QueryExecutor.stub(:execute_philosopher_query, rows) do
          assert_no_difference("Philosopher.count") { run_task("populate", "true") }
        end
      end
    end
    assert_includes errors.first.first.message, "bad entity"
    assert_equal "shadow:populate urk", errors.first.last
  end

  test "label refresh replaces old names and updates relative language frequency" do
    attributes = {linkcount: 12, names_attributes: [{"shadow_id" => @figure.id, "label" => "Refreshed", "lang" => "en"},
      {"shadow_id" => @figure.id, "label" => "Rafraîchi", "lang" => "fr"}]}
    @receiver.stub(:labels, attributes) { capture_io { @receiver.send(:update_labels, @figure) } }
    assert_equal %w[Refreshed Rafraîchi].sort, @figure.names.reload.pluck(:label).sort
    assert_equal 12, @figure.reload.linkcount
    @figure.names.create!(lang: "en_match", label: "Alias")
    with_progress do
      @receiver.send(:langorder, false, [@figure.id])
      @receiver.send(:langorder, false)
    end
    assert_operator @figure.names.find_by!(lang: "en").langorder, :>=, 1
    assert_nil @figure.names.find_by!(lang: "en_match").langorder
  end

  test "label task and count task honor their selected population" do
    rows = Philosopher.where(id: @figure.id)
    @receiver.stub(:select, rows) do
      @receiver.stub(:labels, {linkcount: 2, names_attributes: [{"shadow_id" => @figure.id, "label" => "Updated", "lang" => "en"}]}) do
        with_progress { run_task("phil_labels", "philosophers") }
      end
      assert_includes run_task("count", "philosophers"), "1"
    end
    assert_equal "Updated", @figure.reload.english
    assert_includes run_task("help"), "populate"
  end

  test "year normalization applies historical date corrections and updates delegated year fields" do
    [9333, 10261, 59138, 76501, 967356, 258369, 165589, 188332, 320546, 335371, 428694, 457990, 556865, 960345].each do |id|
      Philosopher.create!(entity_id: id) unless Philosopher.exists?(entity_id: id)
    end
    with_progress { run_task("year") }
    assert_equal(-604, Philosopher.find_by!(entity_id: 9333).birth_year)
    assert_equal(-497, Philosopher.find_by!(entity_id: 10261).death_year)
    assert_equal 1882, Philosopher.find_by!(entity_id: 76501).birth_year
    assert_equal 1804, @other.reload.death_year
  end

  test "gender distribution reads delegated years and handles repeated century buckets" do
    @figure.update!(birth_year: 1800, gender: "Q6581097")
    @other.update!(birth_year: 1810, gender: "Q6581097")
    female = create_test_philosopher(birth_year: nil, death_year: 1850, gender: "Q6581072")
    unknown = create_test_philosopher(birth_year: nil, death_year: nil)
    relation = Philosopher.where(id: [@figure.id, @other.id, female.id, unknown.id])
    output = nil
    Philosopher.stub(:all, relation) { with_progress { output = run_task("gender") } }
    assert_includes output, "No data for 1"
    buckets = output.lines.grep(/\A\[/).map { |line| JSON.parse(line.gsub("nil", "null")) }
    assert_equal 2, buckets[0][1]
    assert_equal 1, buckets[1][1]
    assert_equal "50.00%", buckets[2][1]
    assert_equal 0, @receiver.send(:which_slot, 2000)
    assert_equal 1, @receiver.send(:which_slot, 1800)
  end

  test "progress spinner prints a running frame and always stops its worker thread" do
    wrapper = @receiver.singleton_class.ancestors.find { |ancestor| ancestor.const_defined?(:ProgressSpinner, false) }
    spinner = wrapper.const_get(:ProgressSpinner).new("Metadata")
    ready = Queue.new
    spinner.stub(:sleep, ->(*) {
                           ready << true
                           Thread.stop
                         }) do
      output = capture_io do
        spinner.start
        Timeout.timeout(2) { ready.pop }
        spinner.stop("Completed")
        spinner.instance_variable_get(:@thread).join
      end.first
      assert_includes output, "Metadata"
      assert_includes output, "Completed"
    end
    refute spinner.instance_variable_get(:@thread).alive?
    spinner.instance_variable_set(:@start_time, Time.now - 75)
    assert_match(/1m 15\.\ds/, capture_io { spinner.stop }.first)
  ensure
    spinner&.instance_variable_get(:@thread)&.kill
  end

  private

  def run_task(name, *arguments)
    task = Rake::Task["shadow:philosopher:#{name}"]
    task.reenable
    Rails.stub(:root, Pathname.new(@directory)) { capture_io { task.invoke(*arguments) }.first }
  end

  def with_progress(&block)
    with_task_progress(@receiver, &block)
  end

  def entity(id)
    RDF::URI("http://www.wikidata.org/entity/Q#{id}")
  end

  def solutions(*rows)
    RDF::Query::Solutions.new(rows.map { |bindings| RDF::Query::Solution.new(bindings) })
  end
end
