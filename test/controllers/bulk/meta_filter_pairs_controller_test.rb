require "test_helper"

class Bulk::MetaFilterPairsControllerTest < ActionController::TestCase
  test "creates a saved query with its serialised parameters" do
    assert_difference("QuestionMetaFilter.count") do
      assert_difference("MetaFilterPair.count", 2) do
        post :create, meta: ["Citizenship query"], multiplex: "country", ids: ["42", "84"]
      end
    end

    filter = assigns(:meta_filter)
    assert_redirected_to bulk_meta_filter_pair_path(filter)
    assert_equal "Citizenship query", filter.filter
    assert_equal ["42", "84"], filter.meta_filter_pairs.find_by(key: "ids").value
    assert_equal "country", filter.meta_filter_pairs.find_by(key: "multiplex").value
  end

  test "updates existing saved query parameters" do
    filter = QuestionMetaFilter.create!(filter: "Existing query")
    pair = filter.meta_filter_pairs.create!(key: "ids", value: ["42"])

    patch :update, id: filter.id, ids: ["84", "126"]

    assert_redirected_to bulk_meta_filter_pair_path(filter)
    assert_equal ["84", "126"], pair.reload.value
  end

  test "adds and removes selected entities from an existing query" do
    filter = QuestionMetaFilter.create!(filter: "Existing query")
    pair = filter.meta_filter_pairs.create!(key: "ids", value: ["42"])

    patch :update, id: filter.id, extra_ids: ["84"], op: "+"
    assert_equal ["42", "84"], pair.reload.value

    patch :update, id: filter.id, extra_ids: ["42"], op: "-"
    assert_equal ["84"], pair.reload.value
  end
end
