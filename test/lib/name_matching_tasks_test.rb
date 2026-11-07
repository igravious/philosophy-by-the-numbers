require "test_helper"
require "minitest/mock"
require "rake"
require_relative "../support/rake_task_testing"
require "sparql/client"

class NameMatchingTasksTest < ActiveSupport::TestCase
  include RakeTaskTesting
  setup do
    use_rake_tasks(Rails.root.join("lib/tasks/names.rake"))
    @plain = create_test_philosopher
    @accented = create_test_philosopher
    @plain.names.create!(lang: "en", label: "Plato")
    @accented.names.create!(lang: "en", label: "René Descartes")
    @figures = Philosopher.where(id: [@plain.id, @accented.id])
  end

  teardown do
    restore_rake_tasks
  end

  test "matching aliases preserve original names and normalize accented characters without duplicates" do
    Philosopher.stub(:all, @figures) do
      2.times do
        Rake::Task["names:bunny"].reenable
        capture_io { Rake::Task["names:bunny"].invoke }
      end
    end
    assert_equal ["Plato"], @plain.names.where(lang: "en_match").pluck(:label)
    assert_equal ["René Descartes*Rene Descartes"], @accented.names.where(lang: "en_match").pluck(:label)
  end

  test "English label checks execute the real query and report renamed entities" do
    queries = []
    client = Object.new
    client.define_singleton_method(:query) do |query|
      queries << query
      RDF::Query::Solutions.new([RDF::Query::Solution.new(v: RDF::Literal.new("New label"))])
    end
    Philosopher.stub(:all, @figures) do
      SPARQL::Client.stub(:new, client) do
        capture_io { Rake::Task["names:runny"].invoke }
      end
    end
    assert_equal 2, queries.size
    assert_includes queries.first, "rdfs:label"
    assert queries.any? { |query| query.include?("Q#{@accented.entity_id}") }
  end

  test "English label lookup rejects ambiguous result sets" do
    client = Object.new
    client.define_singleton_method(:query) { |_| RDF::Query::Solutions.new }
    receiver = Rake::Task["names:runny"].actions.first.binding.receiver
    SPARQL::Client.stub(:new, client) do
      capture_io { assert_nil receiver.send(:one_label, "Q859") }
    end
  end
end
