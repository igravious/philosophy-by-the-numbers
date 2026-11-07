require 'test_helper'

class PropertyTest < ActiveSupport::TestCase
  test "property can be read from fixtures" do
    property = properties(:one)
    assert_not_nil property
  end

  test "property persists all attributes" do
    property = Property.create!(entity_id: 999, data_id: 888, property_id: 777, data_label: "test property")
    reloaded = Property.find(property.id)
    assert_equal 999, reloaded.entity_id
    assert_equal 888, reloaded.data_id
    assert_equal 777, reloaded.property_id
    assert_equal "test property", reloaded.data_label
  end

  test "property can be destroyed" do
    property = properties(:two)
    assert_difference 'Property.count', -1 do
      property.destroy
    end
  end
end
