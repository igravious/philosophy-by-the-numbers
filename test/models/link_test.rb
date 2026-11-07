require 'test_helper'

class LinkTest < ActiveSupport::TestCase
  test "link can be created with basic attributes" do
    link = Link.new(table_name: "shadows", row_id: 1, IRI: "http://example.org/test", description: "Test link")
    assert link.save
  end

  test "link can be read from fixtures" do
    link = links(:one)
    assert_not_nil link
    assert_not_nil link.id
  end

  test "link persists all attributes" do
    link = Link.create!(table_name: "shadows", row_id: 42, IRI: "http://dbpedia.org/resource/Plato", description: "DBpedia link for Plato")
    reloaded = Link.find(link.id)
    assert_equal "shadows", reloaded.table_name
    assert_equal 42, reloaded.row_id
    assert_equal "http://dbpedia.org/resource/Plato", reloaded.IRI
    assert_equal "DBpedia link for Plato", reloaded.description
  end

  test "link can be destroyed" do
    link = links(:one)
    assert_difference 'Link.count', -1 do
      link.destroy
    end
  end
end
