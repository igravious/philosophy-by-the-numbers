require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  setup do
    @philosopher = create_test_philosopher(entity_id: 970010)
    @capacity = capacities(:one)
  end

  test "role can be created with attributes" do
    role = Role.new(shadow_id: @philosopher.id, entity_id: @capacity.entity_id, label: "Logician")
    assert role.save
  end

  test "role belongs to shadow" do
    role = Role.create!(shadow_id: @philosopher.id, entity_id: @capacity.entity_id, label: "Thinker")
    assert_respond_to role, :shadow
    assert_equal @philosopher, role.shadow
  end

  test "role belongs to capacity via entity_id" do
    role = Role.create!(shadow_id: @philosopher.id, entity_id: @capacity.entity_id, label: "Scholar")
    assert_respond_to role, :capacity
    assert_equal @capacity.entity_id, role.entity_id
  end

  test "role can be destroyed" do
    role = Role.create!(shadow_id: @philosopher.id, entity_id: 999, label: "Temporary")
    assert_difference 'Role.count', -1 do
      role.destroy
    end
  end
end
