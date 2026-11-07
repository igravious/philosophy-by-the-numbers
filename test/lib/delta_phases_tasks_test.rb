require "test_helper"
require "minitest/mock"
require "rake"
require_relative "../support/rake_task_testing"
require "tmpdir"
require_relative "../../lib/delta_analysis/work_based_delta_processor"
require_relative "../../lib/delta_analysis/custom_diff_strategies"

class DeltaPhasesTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  setup do
    @directory = Dir.mktmpdir("delta-phases-")
    use_rake_tasks(Rails.root.join("lib/tasks/delta_phases.rake"))
  end

  teardown do
    restore_rake_tasks
    FileUtils.remove_entry(@directory)
  end

  test "progressive corpus generation preserves texts titles authors and significance" do
    author = create_test_philosopher
    author.names.create!(lang: "en", label: "Plato")
    works = 2.times.map do |index|
      work = create_test_work(measure: 4.0 - index)
      work.names.create!(lang: "en", label: "Work #{index + 1}")
      work.creators << author if index.zero?
      path = File.join(@directory, "text-#{index}.txt")
      File.write(path, "Philosophical text #{index}")
      {work: work, file_path: path}
    end
    processor = Struct.new(:works_with_files).new(works)
    options = []
    WorkBasedDeltaProcessor.stub(:new, ->(settings) {
                                         options << settings
                                         processor
                                       }) do
      run_task("saffron_runs", "2", "3", @directory)
    end

    first = read_json("corpus_0001.json")
    second = read_json("corpus_0002.json")
    assert_equal 1, first.fetch("documents").size
    assert_equal 2, second.fetch("documents").size
    assert_equal ["Plato"], first["documents"][0]["authors"]
    assert_equal ["Unknown"], second["documents"][1]["authors"]
    assert_equal "Philosophical text 0", first["documents"][0]["contents"]
    assert_equal 4.0, first["documents"][0]["metadata"]["significance"]
    assert_equal 2, options.first[:max_works]
    assert_equal "voting", read_json("saffron_config_0001.json")["termExtraction"]["method"]
    assert File.executable?(File.join(@directory, "run_saffron.sh"))
    script = File.read(File.join(@directory, "run_saffron.sh"))
    assert_includes script, File.join(@directory, "corpus_0002.json")
    assert_includes script, "exit 1"
  end

  test "corpus generation skips disappeared files and handles an empty selection" do
    work = create_test_work(measure: 4.0)
    [[{work: work, file_path: File.join(@directory, "missing.txt")}], []].each do |works|
      WorkBasedDeltaProcessor.stub(:new, Struct.new(:works_with_files).new(works)) do
        run_task("saffron_runs", "2", "0", @directory)
      end
      assert File.file?(File.join(@directory, "run_saffron.sh"))
    end
    assert_empty read_json("corpus_0001.json")["documents"]
  end

  test "work counts report the selected file backed populations" do
    WorkBasedDeltaProcessor.stub(:new, Struct.new(:works_with_files).new([:one, :two])) do
      output = run_task("count_works")
      assert_includes output, "Works with text files: 2"
      assert_includes output, "Works with canonicity >= 3.0 and files: 2"
    end
  end

  test "adjacent Saffron outputs produce delta files for each supported strategy" do
    write_results
    %w[term_weight jaccard semantic composite unknown].each do |strategy|
      run_task("calculate_deltas", @directory, strategy)
      summary = read_json("deltas/delta_summary.json")
      assert_equal 2, summary["total_comparisons"], strategy
      assert_equal strategy, summary["strategy"]
      assert_equal "0001", read_json("deltas/D0001.json")["prev_corpus"]["id"]
      assert_equal "0003", read_json("deltas/D0002.json")["curr_corpus"]["id"]
      assert summary["deltas"].all? { |delta| delta["delta"].is_a?(Numeric) }
    end
  end

  test "delta calculation reports failed comparisons without corrupting the summary" do
    write_results
    CustomDiffStrategies::CompositeStrategy.stub(:calculate_delta, ->(*) { raise ArgumentError, "bad input" }) do
      assert_includes run_task("calculate_deltas", @directory), "bad input"
    end
    assert_equal 0, read_json("deltas/delta_summary.json")["total_comparisons"]
  end

  test "phase two rejects missing and incomplete result directories" do
    [File.join(@directory, "absent"), @directory].each do |path|
      error = assert_raises(SystemExit) { run_task("calculate_deltas", path) }
      assert_equal 1, error.status
    end
  end

  test "convergence analysis uses the corpus that produced the later delta" do
    write_delta_summary([0.5, 0.505, 0.8])
    run_task("delta_of_deltas", @directory, "0.01")
    report = read_json("convergence_analysis.json")

    assert report["converged"]
    assert_equal 1, report["converged_at_index"]
    assert_equal 3, report["converged_at_corpus"]
    assert_in_delta 0.005, report["delta_of_deltas"].first, 0.00001
    assert_equal 4, report["analysis"]["total_works_processed"]
  end

  test "convergence analysis reports continued change" do
    write_delta_summary([0.5, 0.7, 0.9])
    run_task("delta_of_deltas", @directory, "0.01")
    report = read_json("convergence_analysis.json")

    refute report["converged"]
    assert_nil report["converged_at_corpus"]
    assert_in_delta 0.9, report["analysis"]["final_delta"], 0.00001
  end

  test "phase three rejects absent or insufficient delta summaries" do
    error = assert_raises(SystemExit) { run_task("delta_of_deltas", @directory) }
    assert_equal 1, error.status
    write_delta_summary([0.5])
    assert_equal 1, assert_raises(SystemExit) { run_task("delta_of_deltas", @directory) }.status
    Dir.stub(:glob, []) do
      assert_equal 1, assert_raises(SystemExit) { run_task("delta_of_deltas") }.status
    end
  end

  private

  def run_task(name, *args)
    task = Rake::Task["delta_phases:#{name}"]
    task.reenable
    capture_io { task.invoke(*args) }.first
  end

  def read_json(path)
    JSON.parse(File.read(File.join(@directory, path)))
  end

  def write_results
    3.times do |index|
      directory = File.join(@directory, "saffron_results", format("%04d", index + 1))
      FileUtils.mkdir_p(directory)
      File.write(File.join(directory, "terms.json"), JSON.generate([{term_string: "ethics", score: 1.0 + index}, {term_string: "logic"}]))
      next if index.zero?
      File.write(File.join(directory, "doc-terms.json"), JSON.generate([{document_id: "work1", term_string: "ethics", tfidf: 0.5},
        {document_id: "work1", term_string: "logic"}]))
    end
    FileUtils.mkdir_p(File.join(@directory, "saffron_results", "incomplete"))
  end

  def write_delta_summary(values)
    FileUtils.mkdir_p(File.join(@directory, "deltas"))
    File.write(File.join(@directory, "deltas/delta_summary.json"), JSON.generate(deltas: values.map { |delta| {delta: delta} }))
  end
end
