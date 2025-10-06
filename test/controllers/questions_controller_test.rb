require 'test_helper'

class QuestionsControllerTest < ActionController::TestCase
  
  test "controller index action works with Ruby 2.6 workaround" do
    # Use our safe controller testing method to bypass Monitor threading issues
    result = safe_controller_get(QuestionsController, :index)
    
    assert_safe_response_success(result)
    assert_not_nil result[:controller]
    assert_kind_of QuestionsController, result[:controller]
    
    # Verify the action sets up the expected instance variables
    controller = result[:controller]
    assert_respond_to controller, :index
    
    # Since we added an index action, verify it works
    assert controller.instance_variable_get(:@property_list).is_a?(Array)
    assert controller.instance_variable_get(:@entity_ids).is_a?(Array)
    assert_equal "Questions", controller.instance_variable_get(:@grouping)
  end
  
  test "controller can be instantiated without threading issues" do
    # This should always work regardless of Monitor issues
    controller = QuestionsController.new
    assert_not_nil controller
    assert_kind_of QuestionsController, controller
    assert_equal 40, QuestionsController::RECORDS_PER_PAGE
  end
end
