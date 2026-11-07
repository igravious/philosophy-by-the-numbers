require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../../lib/delta_analysis/delta_of_delta_processor"

class DeltaOfDeltaProcessorTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir
    @works = 4.times.map do |index|
      path = File.join(@directory, "work_#{index}.txt")
      File.write(path, "Philosophy text #{index}")
      path
    end
    @output = File.join(@directory, "analysis")
    @calls = []
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "cumulative processing preserves work order and reports the converged population" do
    processor = DeltaOfDeltaProcessor.new(works: @works, output_dir: @output, diff_strategy: :term_weight)
    report = nil

    Open3.stub(:capture3, saffron_result) do
      capture_io { report = processor.process }
    end

    assert_equal [@works.take(1), @works.take(2), @works.take(3)], @calls
    assert_equal 3, report[:summary][:total_works_processed]
    assert_equal @works.take(3), report[:works_processed]
    assert report[:summary][:convergence_reached]
    assert_equal 2, report[:deltas_summary].length
    assert_equal 0.0, report[:delta_of_deltas_summary].first[:magnitude]
    persisted = JSON.parse(File.read(File.join(@output, "reports", "final_report.json")))
    assert_equal 3, persisted.fetch("summary").fetch("total_works_processed")
  end

  test "one work still produces a report without claiming convergence" do
    processor = DeltaOfDeltaProcessor.new(works: @works.take(1), output_dir: @output)
    report = nil

    Open3.stub(:capture3, saffron_result) do
      capture_io { report = processor.process }
    end

    assert_not_nil report
    assert_equal 1, report[:summary][:total_works_processed]
    refute report[:summary][:convergence_reached]
    assert_empty report[:deltas_summary]
  end

  test "empty input fails before attempting Saffron" do
    processor = DeltaOfDeltaProcessor.new(works: [], output_dir: @output)

    Open3.stub(:capture3, ->(*) { flunk "Saffron must not run for an empty population" }) do
      assert_raises(ArgumentError) { capture_io { processor.process } }
    end
  end

  test "failed Saffron execution does not write a success report" do
    processor = DeltaOfDeltaProcessor.new(works: @works.take(2), output_dir: @output)
    status = Struct.new(:success?).new(false)
    error = nil

    Open3.stub(:capture3, ["output", "Saffron failed", status]) do
      error = assert_raises(RuntimeError) { capture_io { processor.process } }
    end

    assert_includes error.message, "Saffron failed"
    refute File.exist?(File.join(@output, "reports", "final_report.json"))
    assert_empty processor.results_history
  end

  test "Saffron JSON preserves Unicode terms and document associations" do
    processor = DeltaOfDeltaProcessor.new(works: @works.take(1), output_dir: @output)

    Open3.stub(:capture3, saffron_result) do
      capture_io { processor.process }
    end

    result = processor.results_history.first
    assert_equal 0.5, result[:terms].fetch("ἀρχή").fetch("score")
    assert_equal 2, result[:doc_terms].fetch("document").fetch("ἀρχή").fetch("occurrences")
    assert_equal "A", result[:iteration_id]
  end

  private

  def saffron_result
    ->(*command, **options) do
      corpus = JSON.parse(File.read(command[1]))
      @calls << corpus.fetch("documents").map { |document| document.fetch("file") }
      assert_equal DeltaOfDeltaProcessor::SAFFRON_PATH, options[:chdir]
      directory = command[2]
      FileUtils.mkdir_p(directory)
      File.write(File.join(directory, "terms.json"), JSON.generate([
        {"term_string" => "ἀρχή", "score" => 0.5, "occurrences" => 2}
      ]))
      File.write(File.join(directory, "doc-terms.json"), JSON.generate([
        {"document_id" => "document", "term_string" => "ἀρχή", "occurrences" => 2, "tfidf" => 0.25}
      ]))
      ["", "", Struct.new(:success?).new(true)]
    end
  end
end
