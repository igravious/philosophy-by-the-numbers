require 'test_helper'
require 'delivery'

class DeliveryTest < ActiveSupport::TestCase
  test "has expected attributes" do
    d = Delivery.new
    assert_respond_to d, :identifier
    assert_respond_to d, :location
    assert_respond_to d, :date
    assert_respond_to d, :numbered
    assert_respond_to d, :amount
    assert_respond_to d, :play
  end

  test "consistent returns SHA1 hex digest" do
    d = Delivery.new
    d.identifier = 'test-id'
    d.location = 'test-loc'
    d.date = '2024-01-01'
    result = d.consistent
    assert_match(/\A[0-9a-f]{40}\z/, result)
  end

  test "consistent is deterministic" do
    d1 = Delivery.new(identifier: 'a', location: 'b', date: 'c')
    d2 = Delivery.new(identifier: 'a', location: 'b', date: 'c')
    assert_equal d1.consistent, d2.consistent
  end

  test "consistent changes with different inputs" do
    d1 = Delivery.new(identifier: 'a', location: 'b', date: 'c')
    d2 = Delivery.new(identifier: 'x', location: 'b', date: 'c')
    assert_not_equal d1.consistent, d2.consistent
  end

  test "SEED constant is defined" do
    assert_equal 0xfabaceae, Delivery::SEED
  end

  test "includes ActiveModel::Model" do
    assert Delivery.ancestors.include?(ActiveModel::Model)
  end

  test "can be initialised with hash" do
    d = Delivery.new(identifier: 'id', location: 'loc', date: 'dt', numbered: 5, amount: 10, play: 'go')
    assert_equal 'id', d.identifier
    assert_equal 'loc', d.location
    assert_equal 'dt', d.date
    assert_equal 5, d.numbered
    assert_equal 10, d.amount
    assert_equal 'go', d.play
  end
end
