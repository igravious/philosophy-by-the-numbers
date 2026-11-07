require "test_helper"
require "minitest/mock"
require "tmpdir"
require_relative "../../lib/delta_analysis/work_based_delta_processor"

class WorkBasedDeltaProcessorTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir("work-deltas-")
    @philosopher = create_test_philosopher
    @philosopher.names.create!(lang: "en", label: "Coverage Author")
    @author = Author.create!(name: "Coverage Author", english_name: "Coverage Author")
    @works = 3.times.map do |index|
      work = create_test_work(measure: 9.0 - index, linkcount: 10 + index, obsolete: false)
      work.names.create!(lang: "en", label: "Work #{index}")
      work.creators << @philosopher
      work
    end
    @path = File.join(@directory, "text.txt")
    File.write(@path, "Philosophical content")
    fyle = Fyle.create!(what: "Coverage Text", local_file: @path)
    text = Text.create!(name: "Coverage Text", fyle: fyle)
    Writing.create!(text: text, author: @author, role: Writing::AUTHOR)
    @processor = WorkBasedDeltaProcessor.allocate
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "selection strategies use the actual SQLite schema and exclude obsolete works" do
    obsolete = create_test_work(measure: 999.0, linkcount: 999, obsolete: true)
    expected = {
      canonicity: @works,
      linkcount: @works.reverse,
      mixed: @works,
      random: nil,
      recent: @works.reverse
    }
    relation = Work.where(id: @works.map(&:id) + [obsolete.id])
    Work.stub(:joins, ->(*) { relation.joins(:attrs) }) do
      expected.each do |strategy, ordered|
        @processor.instance_variable_set(:@work_selection_strategy, strategy)
        @processor.instance_variable_set(:@max_works, 3)
        selected = @processor.send(:select_works).to_a
        assert_equal @works.map(&:id).sort, selected.map(&:id).sort, strategy
        assert_equal ordered.map(&:id), selected.map(&:id), strategy if ordered
      end
      @processor.instance_variable_set(:@min_canonicity, 8.5)
      assert_equal [@works.first.id], @processor.send(:select_by_canonicity).map(&:id)
    end
    @processor.instance_variable_set(:@work_selection_strategy, :invalid)
    assert_raises(ArgumentError) { @processor.send(:select_works) }
  end

  test "file lookup follows the real creator author text and fyle relationships" do
    assert_equal @path, @processor.send(:get_text_file_path, @works.first)
    assert_equal [@path], @processor.send(:extract_text_files_for_processing, [@works.first])
    assert_equal [{work: @works.first, file_path: @path}], @processor.send(:prepare_works_with_files, [@works.first])
    FileUtils.rm(@path)
    assert_nil @processor.send(:get_text_file_path, @works.first)
    assert_empty @processor.send(:extract_text_files_for_processing, [@works.first])
    assert_empty @processor.send(:prepare_works_with_files, [@works.first])
    assert_equal ["Coverage Author"], @processor.send(:work_philosophers, @works.first)
  end

  test "factory methods preserve their selection settings and input file order" do
    factories = {by_canonicity: :canonicity, by_linkcount: :linkcount, mixed_ranking: :mixed, random_sample: :random}
    relation = Work.where(id: @works.map(&:id))
    Work.stub(:joins, ->(*) { relation.joins(:attrs) }) do
      factories.each do |factory, strategy|
        processor = nil
        capture_io { processor = WorkBasedDeltaProcessor.public_send(factory, max_works: 2, output_dir: @directory) }
        assert_equal strategy, processor.work_selection_strategy
        assert_equal 2, processor.max_works
        assert_equal [@path, @path], processor.works
      end
    end
  end

  test "incremental Saffron corpora include author identities and significance positions" do
    Rails.stub(:root, Pathname.new(@directory)) do
      directory = @processor.send(:create_saffron_temp_dir)
      paths = @processor.send(:generate_incremental_saffron_corpora, @works.map { |work| {work: work, file_path: @path} }, directory)
      assert_equal 3, paths.size
      documents = JSON.parse(File.read(paths.last))["documents"]
      assert_equal 3, documents.size
      assert_equal "Coverage Author", documents.first["authors"].first["name"]
      assert_equal "Q#{@philosopher.entity_id}", documents.first["authors"].first["id"]
      assert_equal [1, 2, 3], documents.map { |document| document["metadata"]["significance_rank"] }
      assert_equal [3], documents.map { |document| document["metadata"]["total_in_corpus"] }.uniq
    end
  end

  test "processing writes the enhanced report with work identities and selection criteria" do
    processor = nil
    relation = Work.where(id: @works.first.id)
    Work.stub(:joins, ->(*) { relation.joins(:attrs) }) do
      capture_io { processor = WorkBasedDeltaProcessor.by_canonicity(max_works: 1, min_canonicity: 8.5, output_dir: @directory) }
    end
    execute = ->(*command, **_) do
      FileUtils.mkdir_p(command[2])
      File.write(File.join(command[2], "terms.json"), "[]")
      ["", "", Struct.new(:success?).new(true)]
    end
    report = nil
    Open3.stub(:capture3, execute) { capture_io { report = processor.process } }
    assert_equal @works.first.id, report[:work_metadata].first[:id]
    assert_equal({min_canonicity: 8.5, max_works: 1}, report[:selection_criteria])
    assert_equal "canonicity", JSON.parse(File.read(File.join(@directory, "reports/enhanced_final_report.json")))["selection_strategy"]
  end
end
