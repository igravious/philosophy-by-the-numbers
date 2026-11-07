require "test_helper"

class CanonicityWorkFlagImportTest < ActiveSupport::TestCase
  def with_file(rows)
    file = Tempfile.new(["work-flags", ".json"], Rails.root.join("tmp").to_s)
    file.write(JSON.generate(rows))
    file.close
    yield file.path
  ensure
    file&.unlink
  end

  test "imports all reference flags and typed source events in one transaction" do
    work = create_test_work(entity_id: 42, cambridge: false, borchert: true, routledge: false)

    with_file([[42, "Work", "y", "n", "y"]]) do |path|
      Canonicity::WorkFlagImport.new(path).call
    end

    work.reload
    assert work.cambridge?
    assert_not work.borchert?
    assert work.routledge?
    events = SourceEvent.where(shadow_id: work.id, source_name: "reference_work_flags")
    assert_equal 3, events.count
    assert_equal false, events.find_by!(attribute_name: "cambridge").old_value
    assert_equal true, events.find_by!(attribute_name: "cambridge").new_value
    assert_equal true, events.find_by!(attribute_name: "borchert").old_value
    assert_equal false, events.find_by!(attribute_name: "borchert").new_value
  end

  test "validates the entire file before making any changes" do
    work = create_test_work(entity_id: 42, cambridge: false)

    with_file([[42, "Work", "y", "n", "n"], [999_999, "Missing", "y", "y", "y"]]) do |path|
      assert_raises(Canonicity::ImportError) do
        Canonicity::WorkFlagImport.new(path).call
      end
    end

    assert_not work.reload.cambridge?
    assert_equal 0, SourceEvent.count
  end

  test "rejects duplicate Work rows before making changes" do
    work = create_test_work(entity_id: 42, cambridge: false)

    with_file([[42, "Work", "y", "n", "n"], [42, "Work", "n", "y", "y"]]) do |path|
      assert_raises(Canonicity::ImportError, /Duplicate Work Q42/) do
        Canonicity::WorkFlagImport.new(path).call
      end
    end

    assert_not work.reload.cambridge?
    assert_equal 0, SourceEvent.count
  end
end
