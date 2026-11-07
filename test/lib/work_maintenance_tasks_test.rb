require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../support/rake_task_testing"

class WorkMaintenanceTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting

  setup do
    use_rake_tasks(Rails.root.join("lib/tasks/shadow/work_tasks.rake"))
    @receiver = Rake::Task["shadow:work:show"].actions.first.binding.receiver
    @directory = Dir.mktmpdir("work-maintenance-")
    FileUtils.mkdir_p(File.join(@directory, "log"))
    FileUtils.mkdir_p(File.join(@directory, "tmp"))
    @figure = create_test_philosopher
    @figure.names.create!(lang: "en", label: "Work Author")
    @works = 2.times.map do |index|
      work = create_test_work(measure: 9.0 - index, linkcount: 10 + index, obsolete: false)
      work.names.create!(lang: "en", label: "Example Work #{index}")
      work.creators << @figure
      work
    end
  end

  teardown do
    restore_rake_tasks
    FileUtils.remove_entry(@directory)
  end

  test "work exploration prints both query strategies and returned work identities" do
    row = {item: entity(@figure.entity_id), work: entity(@works.first.entity_id), workLabel: RDF::Literal.new("Returned Work"),
      whatLabel: RDF::Literal.new("Treatise"), linkcount: RDF::Literal.new(5)}
    Wikidata::QueryExecutor.stub(:execute, solutions(row)) do
      %w[authored_by_philosophers of_philosophical_type].each do |strategy|
        assert_includes run_task("show", strategy, "count"), "Got 1 of 'em"
        assert_includes run_task("show", strategy), "Returned Work"
      end
    end
    assert_includes run_task("show"), "Available conditions"
  end

  test "query preview prints SPARQL without executing a remote request" do
    Wikidata::QueryExecutor.stub(:execute, ->(*) { flunk "Query preview must not execute" }) do
      %w[authored_by_philosophers of_philosophical_type].each do |strategy|
        task = Rake::Task["shadow:work:show"]
        task.reenable
        output = capture_io { assert_equal 0, assert_raises(SystemExit) { task.invoke(strategy, "-1") }.status }.first
        assert_includes output, "SELECT"
      end
    end
  end

  test "work discovery creates real philosopher expressions and skips unknown creators" do
    rows = solutions({item: entity(@figure.entity_id), work: entity(7_654_321), workLabel: RDF::Literal.new("Discovered Work"), linkCount: RDF::Literal.new(25)},
      {item: entity(7_654_320), work: entity(7_654_322), workLabel: RDF::Literal.new("Unmatched Work"), linkCount: RDF::Literal.new(1)})
    with_task_progress(@receiver) do
      Wikidata::QueryExecutor.stub(:execute_simple, rows) do
        assert_difference("Work.count", 1) { assert_includes run_task("populate", "works1"), "Can't find philosopher" }
      end
    end
    work = Work.find_by!(entity_id: 7_654_321)
    assert_equal 25, work.linkcount
    assert Expression.exists?(creator_id: @figure.id, work_id: work.id)
    assert_includes run_task("populate"), "Work it baby"
  end

  test "work discovery chooses both documented query templates" do
    queries = []
    @receiver.stub(:deez_wurks, ->(query) { queries << query }) do
      run_task("populate", "works1")
      run_task("populate", "works2")
    end
    assert_equal 2, queries.size
    assert queries.all? { |query| query.include?("SELECT") }
    refute_equal queries.first, queries.last
  end

  test "work connections record direct title and author matches without changing corpus records" do
    @works.first.names.find_by!(lang: "en").update!(label: "Author's Work")
    direct = Text.create!(name: "Direct", name_in_english: "Author's Work")
    by_author = Text.create!(name: "Author Text", name_in_english: "Author Text")
    author = Author.create!(name: "Work Author", english_name: "Work Author")
    Writing.create!(author: author, text: by_author, role: Writing::AUTHOR)
    with_task_progress(@receiver) { Dir.chdir(@directory) { run_task("connect") } }
    log = File.read(File.join(@directory, "log/task_output.log"))
    assert_includes log, direct.name_in_english
    assert_includes log, by_author.name_in_english
    assert_includes log, "==> Q#{@figure.entity_id} (1/1)"
  end

  test "work label refresh selects nonobsolete works by philosopher identity or row ID" do
    obsolete = create_test_work(obsolete: true)
    obsolete.creators << @figure
    updated = []
    scopes = []
    @receiver.stub(:update_labels, ->(work) { updated << work.id }) do
      @receiver.stub(:langorder, ->(force, ids) { scopes << ids }) do
        run_task("work_labels", "Q#{@figure.entity_id}")
        run_task("work_labels", @figure.id.to_s)
        run_task("work_labels", "unknown")
      end
    end
    assert_equal @works.map(&:id).sort * 2, updated.each_slice(2).map(&:sort).flatten
    assert_equal [@works.map(&:id).sort] * 2, scopes.map(&:sort)
  end

  test "genre classification persists known works and reports missing work labels" do
    rows = solutions({work: entity(@works.first.entity_id), workLabel: RDF::Literal.new("Existing")},
      {work: entity(7_654_321), workLabel: RDF::Literal.new("Missing Named Work")},
      {work: entity(7_654_322), workLabel: RDF::Literal.new("Q7654322")})
    with_task_progress(@receiver) do
      Wikidata::QueryExecutor.stub(:execute, rows) do
        assert_includes run_task("signal3"), "Missing Named Work"
      end
    end
    assert @works.first.reload.genre
  end

  test "publication enrichment handles actual metadata fields and normalized dates" do
    attributes = {linkcount: 42, pub_dates: "1859-11-24", title: "Ignored", births: "1809", deaths: "1882", gender: "Ignored", work_lang: "Q1860"}
    @receiver.stub(:properties, ->(*) { attributes.dup }) do
      with_task_progress(@receiver) { run_task("signal1") }
    end
    assert_equal "1859-11-24", @works.first.reload.pub
    assert_equal "1859", @works.first.pub_year
    assert_equal "Q1860", @works.first.work_lang
    assert_equal 42, @works.first.linkcount
  end

  test "per-work exploration preserves order limits and real RDF result sets" do
    calls = []
    rows = RDF::Graph.new
    rows << [entity(1), RDF::URI("http://example.test/property"), entity(2)]
    Wikidata::QueryExecutor.stub(:execute_simple, ->(query, *_) { calls << query; rows }) do
      with_task_progress(@receiver) do
        yielded = []
        @receiver.send(:one_by_one, :describe, "DESCRIBE wd:Q%{interpolated_entity}", {measure: :desc}, 1) do |results, work|
          assert_same rows, results
          yielded << work.id
        end
        assert_equal [@works.first.id], yielded
        assert_includes run_task("describe", "1"), "http://example.test/property"
      end
    end
    assert_equal 2, calls.size
  end

  test "exclusion classification persists only works with a matching RDF property" do
    response = lambda do |query, *_|
      query.include?("wd:Q#{@works.first.entity_id} ") ? solutions(p: RDF::URI("http://example.test/property")) : solutions({})
    end
    Wikidata::QueryExecutor.stub(:execute_simple, response) do
      with_task_progress(@receiver) { run_task("expunge") }
    end
    assert @works.first.reload.obsolete
    refute @works.last.reload.obsolete
  end

  test "position updates preserve immutable completed-run snapshots" do
    {"2.1" => {"routledge" => 0.17, "stanford" => 0.10, "all_bonus" => 0.08},
     "2.0-work" => {"borchert" => 0.25, "cambridge" => 0.20, "routledge" => 0.25,
                    "philpapers" => 0.20, "all_bonus" => 0.10, "genre_philosophical" => 1.0, "genre_other" => 0.5}}.each do |version, sources|
      sources.each do |source, weight|
        CanonicityWeights.find_or_initialize_by(algorithm_version: version, source_name: source)
          .update!(weight_value: weight, active: true)
      end
    end
    figures = Canonicity::DatasetCapture.new(subject_type: "Philosopher").call
    Canonicity::MetricRunCalculator.new(dataset: figures).call
    dataset = Canonicity::DatasetCapture.new(subject_type: "Work").call
    run = Canonicity::MetricRunCalculator.new(dataset: dataset).call
    frozen_positions = run.metric_snapshots.order(:shadow_id).pluck(:shadow_id, :measure_pos)
    with_task_progress(@receiver) { run_task("order2") }
    assert_equal [1, 2], @works.map { |work| work.reload.measure_pos }
    assert_equal frozen_positions, run.metric_snapshots.order(:shadow_id).pluck(:shadow_id, :measure_pos)
  end

  test "position updates continue ranking legacy snapshots" do
    snapshot = MetricSnapshot.create_snapshot_for_work(@works.first, @works.first.measure)
    with_task_progress(@receiver) { run_task("order2") }
    assert_equal 1, snapshot.reload.measure_pos
    with_task_progress(@receiver) { run_task("order2") }
    assert_equal 1, snapshot.reload.measure_pos
  end

  private

  def run_task(name, *arguments)
    task = Rake::Task["shadow:work:#{name}"]
    task.reenable
    capture_io { task.invoke(*arguments) }.first
  end

  def entity(id)
    RDF::URI("http://www.wikidata.org/entity/Q#{id}")
  end

  def solutions(*rows)
    RDF::Query::Solutions.new(rows.map { |bindings| RDF::Query::Solution.new(bindings) })
  end
end
