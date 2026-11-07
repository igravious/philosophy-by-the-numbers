require 'test_helper'

class CapacityTest < ActiveSupport::TestCase
  test "capacity can be read from fixtures" do
    capacity = capacities(:one)
    assert_not_nil capacity
    assert_equal "Test Capacity", capacity.label
  end

  test "capacity has many roles" do
    capacity = capacities(:one)
    assert_respond_to capacity, :roles
  end

  test "toggle_relevant switches true to false" do
    capacity = capacities(:one)
    assert capacity.relevant
    capacity.toggle_relevant
    assert_not capacity.relevant
  end

  test "toggle_relevant switches false to true" do
    capacity = capacities(:two)
    assert_not capacity.relevant
    capacity.toggle_relevant
    assert capacity.relevant
  end

  test "column_direction returns asc for label" do
    assert_equal 'asc', Capacity.column_direction('label')
  end

  test "column_direction returns desc for roles_count" do
    assert_equal 'desc', Capacity.column_direction('roles_count')
  end

  test "column_direction returns desc for relevant" do
    assert_equal 'desc', Capacity.column_direction('relevant')
  end

  test "column_direction returns desc for unknown columns" do
    assert_equal 'desc', Capacity.column_direction('anything_else')
  end

  test "capacity can be created" do
    capacity = Capacity.new(entity_id: 999, label: "New Capacity", relevant: true)
    assert capacity.save
  end

  test "capacity can be destroyed" do
    capacity = capacities(:two)
    assert_difference 'Capacity.count', -1 do
      capacity.destroy
    end
  end
end
