require 'test_helper'

class ExpressionTest < ActiveSupport::TestCase
  setup do
    @philosopher = create_test_philosopher(entity_id: 970001)
    @work = create_test_work(entity_id: 870001)
  end

  test "expression belongs to work" do
    expr = Expression.create!(creator_id: @philosopher.id, work_id: @work.id)
    assert_respond_to expr, :work
    assert_equal @work.id, expr.work_id
  end

  test "expression belongs to philosopher" do
    expr = Expression.create!(creator_id: @philosopher.id, work_id: @work.id)
    assert_respond_to expr, :philosopher
    assert_equal @philosopher.id, expr.creator_id
  end

  test "compose creates new expression from philosopher and work" do
    expression = Expression.compose(@philosopher, @work)
    assert_equal @philosopher.id, expression.creator_id
    assert_equal @work.id, expression.work_id
  end

  test "expression can be saved" do
    expression = Expression.compose(@philosopher, @work)
    assert expression.save
  end
end
