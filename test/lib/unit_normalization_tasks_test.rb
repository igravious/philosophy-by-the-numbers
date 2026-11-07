require "test_helper"
require "minitest/mock"
require "rake"
require_relative "../support/rake_task_testing"
require "knowledge"

class UnitNormalizationTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  setup do
    use_rake_tasks(Rails.root.join("lib/tasks/units_normalise.rake"))
    @receiver = Rake::Task["units:normalise"].actions.first.binding.receiver
    @dictionary = Dictionary.create!(title: "Normalization coverage")
  end

  teardown do
    restore_rake_tasks
  end

  test "proper noun detection requires each word to have a capitalized form" do
    {"Plato" => true, "René Descartes" => true, "logic" => false, "UPPER" => false, "Plato 2" => false}.each do |entry, expected|
      assert_equal expected, @receiver.send(:is_proper?, Unit.new(entry: entry))
    end
  end

  test "WordNet lookup distinguishes common proper absent and inconsistent nouns" do
    noun = Struct.new(:word_counts)
    lemma = Struct.new(:word, :synsets)
    [[lemma.new("logic", [noun.new({"logic" => 1})]), true], [lemma.new("logic", [noun.new({"Logic" => 1})]), false]].each do |value, expected|
      WordNet::Lemma.stub(:find, value) { capture_io { assert_equal expected, @receiver.send(:is_common_noun?, "Logic") } }
    end
    WordNet::Lemma.stub(:find, nil) { capture_io { assert_raises(Knowledge::WordNet::LemmaNotFound) { @receiver.send(:is_common_noun?, "Missing") } } }
    WordNet::Lemma.stub(:find, lemma.new("other", [])) do
      capture_io { assert_raises(Knowledge::WordNet::LemmaPeculiar) { @receiver.send(:is_common_noun?, "Logic") } }
    end
  end

  test "normalization persists common noun and linked data classifications" do
    flags = GlobalConstants::Unit
    result = [RDF::Query::Solution.new(entity: RDF::URI("http://example.test/person"))]
    cases = [
      [true, [], [], nil, flags::COMMON | flags::ABSTRACT],
      [false, result, [], nil, flags::PERSON | flags::INSTANCE | flags::PHILOSOPHY],
      [false, [], result, nil, flags::PERSON | flags::INSTANCE],
      [false, [], [], {"@type" => ["Thing", "Person"], "description" => "Philosopher"}, flags::PERSON | flags::INSTANCE | flags::PHILOSOPHY],
      [false, [], [], {"@type" => ["Person"], "description" => "Scientist"}, flags::PERSON | flags::INSTANCE],
      [false, [], [], {"@type" => ["Thing"]}, flags::PROPER],
      [false, [], [], nil, flags::PROPER]
    ]
    cases.each_with_index do |(common, philosophers, people, google, expected), index|
      unit = Unit.create!(dictionary: @dictionary, entry: "Coverage Name")
      @receiver.stub(:is_common_noun?, common) do
        Knowledge::DBpedia.stub(:is_a_philosopher?, philosophers) do
          Knowledge::DBpedia.stub(:is_a_person?, people) do
            Knowledge::Google.stub(:entity_search, google) do
              Knowledge::LanguageLayer.stub(:detect, [{"language_code" => "en"}]) do
                capture_io { @receiver.send(:process, @dictionary.id) }
              end
            end
          end
        end
      end
      assert_equal expected, unit.reload.what_it_is.to_i, "classification #{index}"
      unit.destroy!
    end
  end

  test "lookup failures do not overwrite a unit or prevent subsequent processing" do
    unit = Unit.create!(dictionary: @dictionary, entry: "Coverage Name", what_it_is: 0)
    @receiver.stub(:is_common_noun?, ->(*) { raise Knowledge::WordNet::LemmaNotFound }) do
      Knowledge::DBpedia.stub(:is_a_philosopher?, ->(*) { raise IOError, "offline" }) do
        assert_includes capture_io { @receiver.send(:process, @dictionary.id) }.first, "offline"
      end
    end
    assert_equal 0, unit.reload.what_it_is.to_i
  end

  test "normalization rejects an implicit population and processes explicit dictionary lists" do
    assert_includes invoke.first, "no params"
    assert_includes invoke("all").first, "use with caution"
    requested = []
    @receiver.stub(:process, ->(id) { requested << id }) { invoke("12", "34") }
    assert_equal ["12", "34"], requested
    capture_io { Rake::Task["units:all:all"].invoke }
  end

  private

  def invoke(*arguments)
    Rake::Task["units:normalise"].reenable
    capture_io { Rake::Task["units:normalise"].invoke(*arguments) }
  end
end
