require 'test_helper'

class PSmartTest < ActiveSupport::TestCase
  test "property class method resolves P property by numeric id" do
    assert_equal P::P19, P::Smart.property(19)
    assert_equal P::P20, P::Smart.property(20)
    assert_equal P::P27, P::Smart.property(27)
    assert_equal P::P31, P::Smart.property(31)
    assert_equal P::P1412, P::Smart.property(1412)
  end

  test "property_id extracts numeric id from type" do
    record = P::Smart.new
    record.type = 'P::P27'
    assert_equal 27, record.property_id
  end

  test "property_id extracts large numeric id" do
    record = P::Smart.new
    record.type = 'P::P1412'
    assert_equal 1412, record.property_id
  end

  test "original_id aliases entity_id" do
    record = P::Smart.new
    record.entity_id = 42
    assert_equal 42, record.original_id
  end

  test "data_id aliases object_id for P::Smart" do
    record = P::Smart.new
    record[:object_id] = 99
    assert_equal 99, record.data_id
  end

  test "data_label aliases object_label" do
    record = P::Smart.new
    record.object_label = 'Athens'
    assert_equal 'Athens', record.data_label
  end

  test "dbpedia_property extracts ontology suffix" do
    result = P::Smart.dbpedia_property('http://dbpedia.org/ontology/philosophicalSchool')
    assert_equal 'philosophicalSchool', result
  end

  test "entity_label returns label when shadow and name exist" do
    phil = create_test_philosopher
    Name.create!(shadow_id: phil.id, lang: 'en', label: 'Aristotle')
    record = P::Smart.new
    record.entity_id = phil.entity_id
    assert_equal 'Aristotle', record.entity_label
  end

  test "entity_label returns ! when no shadow found" do
    record = P::Smart.new
    record.entity_id = 999999
    assert_equal '!', record.entity_label
  end

  test "entity_label returns ? when shadow exists but no English name" do
    phil = create_test_philosopher
    record = P::Smart.new
    record.entity_id = phil.entity_id
    assert_equal '?', record.entity_label
  end

  test "composite primary keys are defined" do
    assert_equal %w[redirect_id object_id type], P::Smart.primary_keys
  end

  test "P subclasses inherit from P::Smart" do
    [P::P19, P::P20, P::P27, P::P31, P::P1412, P::D1, P::D2, P::D3, P::J1, P::J27].each do |klass|
      assert klass < P::Smart, "#{klass} should inherit from P::Smart"
    end
  end
end
