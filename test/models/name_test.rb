require 'test_helper'

class NameTest < ActiveSupport::TestCase
  setup do
    @philosopher = create_test_philosopher(entity_id: 970030)
    @name = Name.create!(shadow_id: @philosopher.id, label: "Test Philosopher", lang: "en", langorder: 10)
  end

  test "name belongs to shadow" do
    assert_respond_to @name, :shadow
    assert_not_nil @name.shadow
    assert_equal @philosopher.id, @name.shadow_id
  end

  test "first_shadow_by_lang_order returns name for valid shadow" do
    result = Name.first_shadow_by_lang_order(@philosopher.id)
    assert_not_nil result
    assert_equal @philosopher.id, result.shadow_id
  end

  test "first_shadow_by_lang_order returns nil for invalid shadow" do
    result = Name.first_shadow_by_lang_order(99999)
    assert_nil result
  end

  test "name can be created" do
    name = Name.new(shadow_id: @philosopher.id, label: "Platón", lang: "es", langorder: 1)
    assert name.save
  end

  test "name can be destroyed" do
    name = Name.create!(shadow_id: @philosopher.id, label: "Temporary", lang: "de", langorder: 2)
    assert_difference 'Name.count', -1 do
      name.destroy
    end
  end
end
