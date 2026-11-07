require "test_helper"
require "minitest/mock"

class TextMutationsTest < ActionController::TestCase
  tests TextsController

  test "JSON creation links the chosen author and returns the persisted text" do
    author = authors(:one)
    assert_difference("Text.count", 1) do
      assert_difference("Writing.count", 1) do
        post :create, format: :json, text: {name: "Created text", author_id: author.id}
      end
    end
    assert_response :created
    assert_equal "Created text", assigns(:text).reload.name
    assert_equal [author.id], assigns(:text).authors.pluck(:id)
    assert_equal assigns(:text).id, JSON.parse(response.body)["id"]
  end

  test "an unknown author cannot leave an orphan text after a failed creation" do
    assert_no_difference("Text.count") do
      post :create, format: :json, text: {name: "Failed creation", author_id: -1}
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Could not find specific author"
  end

  test "a rejected writing rolls back text creation and returns model errors" do
    writing = Writing.new
    writing.errors.add(:base, "Writing rejected")
    Writing.stub(:new, ->(*) { raise ActiveRecord::RecordInvalid, writing }) do
      assert_no_difference("Text.count") do
        post :create, format: :json, text: {name: "Rejected creation", author_id: authors(:one).id}
      end
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Writing rejected"
  end

  test "JSON updates link selected authors and tags and persist text changes" do
    text = texts(:one)
    author = authors(:two)
    tag = tags(:two)
    patch :update, id: text.id, format: :json, text: {name: "Updated text", author_id: author.id, tag_id: tag.id}

    assert_response :no_content
    assert_equal "Updated text", text.reload.name
    assert Writing.exists?(text_id: text.id, author_id: author.id)
    assert Labeling.exists?(text_id: text.id, tag_id: tag.id)
  end

  test "an unknown association cannot partially apply a text update" do
    text = texts(:one)
    original = text.name
    patch :update, id: text.id, format: :json, text: {name: "Should roll back", author_id: -1}

    assert_response :unprocessable_entity
    assert_equal original, text.reload.name
  end

  test "a failed text validation rolls back newly linked authors and tags" do
    text = texts(:one)
    text.errors.add(:base, "Invalid text")
    Text.stub(:find, text) do
      text.stub(:update, false) do
        assert_no_difference("Writing.count") do
          assert_no_difference("Labeling.count") do
            patch :update, id: text.id, format: :json, text: {author_id: authors(:two).id, tag_id: tags(:two).id}
          end
        end
      end
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "Invalid text"
  end

  test "JSON deletion removes associated writings and the text" do
    text = texts(:one)
    assert_difference("Text.count", -1) { delete :destroy, id: text.id, format: :json }
    assert_response :no_content
    refute Writing.exists?(text_id: text.id)
  end

  test "named filters are created updated and retrieved with their selected inclusions" do
    get :index, filter_name: "Coverage Filter", original_year: "1850", inequality: ">"
    filter = Filter.find_by!(name: "Coverage Filter")
    assert_equal 1850, filter.original_year
    assert_equal ">", filter.inequality
    get :index, filter_name: "Coverage Filter", original_year: "1950", inequality: "<"
    assert_equal 1950, filter.reload.original_year
    assert_equal "<", filter.inequality
    Including.create!(filter: filter, text: texts(:one))
    get :index, filter_id: filter.id
    assert_equal filter.id, assigns(:filter).id
    assert_equal [texts(:one).id], assigns(:includings)
  end
end
