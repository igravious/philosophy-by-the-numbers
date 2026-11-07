require "test_helper"
require "minitest/mock"

class DateTimeMethodsTest < ActiveSupport::TestCase
  test "year extraction preserves year-only and ISO dates and rejects malformed source text" do
    {nil => nil, "" => nil, "1724" => 1724, "-470" => -470,
     "1724-04-22" => 1724, "not a date" => nil,
     "\xff".b.force_encoding("UTF-8") => nil}.each do |value, expected|
      assert_equal expected, DateTimeMethods.extract_year(value)
    end
    assert_equal 1859, create_test_work(pub: "1859").year(:pub)
  end

  test "date scopes distinguish today and the current hour for creation and update" do
    now = Time.zone.parse("2026-11-06 14:30:00")
    current = create_test_philosopher
    earlier = create_test_philosopher
    yesterday = create_test_philosopher
    [[current, now], [earlier, now - 2.hours], [yesterday, now - 1.day]].each do |record, time|
      record.update_columns(created_at: time, updated_at: time)
    end
    ids = [current.id, earlier.id, yesterday.id]

    Time.zone.stub(:now, now) do
      assert_equal [current.id, earlier.id].sort, Philosopher.created_today.where(id: ids).pluck(:id).sort
      assert_equal [current.id, earlier.id].sort, Philosopher.updated_today.where(id: ids).pluck(:id).sort
      assert_equal [current.id], Philosopher.created_this_hour.where(id: ids).pluck(:id)
      assert_equal [current.id], Philosopher.updated_this_hour.where(id: ids).pluck(:id)
    end
  end

  test "birth and death labels handle missing and BCE dates" do
    cases = [
      ["-470", nil, "(b. 470 BCE)"], [nil, "-399", "(d. 399 BCE)"],
      ["1724", nil, "(b. 1724)"], [nil, "1804", "(d. 1804)"],
      ["-470", "-399", "(470–399 BCE)"], ["-4", "65", "(4 BCE–65 CE)"]
    ]
    cases.each do |birth, death, expected|
      record = create_test_philosopher(birth: birth, death: death, birth_approx: true, death_approx: true)
      assert_equal expected, record.birth_death
    end
  end

  test "work publication dates use the delegated metadata table" do
    work = create_test_work(pub: "1859-11-24")

    assert_equal 1859, work.year(:pub)
    assert_equal 1859, work.get_year(:pub)
  end

  test "unknown date fields cannot invoke model methods" do
    record = create_test_philosopher

    assert_no_difference("Philosopher.count") do
      assert_nil record.year(:destroy)
      assert_nil record.get_year(:destroy)
    end
    assert record.persisted?
  end
end
