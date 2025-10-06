# Test helper to work around Ruby 2.6.10 + Rails 4.2.11.3 Monitor threading issues
# This provides alternative testing methods that bypass ActionController::TestCase problems

module ThreadErrorWorkarounds
  
  # Alternative to ActionController::TestCase#get that avoids Monitor issues
  def safe_controller_get(controller_class, action, params = {})
    controller = controller_class.new
    request = ActionController::TestRequest.new
    response = create_safe_response
    
    # Set up the request environment
    request.env['REQUEST_METHOD'] = 'GET'
    request.env['PATH_INFO'] = "/#{controller_class.name.underscore.gsub('_controller', '')}"
    request.env['action_dispatch.request.path_parameters'] = {
      controller: controller_class.name.underscore.gsub('_controller', ''),
      action: action.to_s
    }
    
    # Add any parameters
    request.env['action_dispatch.request.query_parameters'] = params
    request.env['QUERY_STRING'] = params.to_query
    
    # Wire up the controller
    controller.request = request
    controller.response = response
    
    # Call the action
    begin
      if controller.respond_to?(action)
        controller.send(action)
      else
        # Handle implicit rendering for actions without methods
        controller.send(:render, action: action)
      end
      
      return {
        controller: controller,
        request: request,
        response: response,
        status: response.status || 200
      }
      
    rescue => e
      return {
        controller: controller,
        request: request,
        response: response,
        error: e,
        status: 500
      }
    end
  end
  
  # Create a response object that avoids Monitor initialization issues
  def create_safe_response
    begin
      ActionDispatch::Response.new
    rescue ThreadError => e
      if e.message.include?('already initialized')
        # Create a minimal response object that works
        response = Object.new
        response.define_singleton_method(:status) { @status ||= 200 }
        response.define_singleton_method(:status=) { |s| @status = s }
        response.define_singleton_method(:headers) { @headers ||= {} }
        response.define_singleton_method(:body) { @body ||= [] }
        response.define_singleton_method(:body=) { |b| @body = b }
        response
      else
        raise e
      end
    end
  end
  
  # Helper to assert successful response without ActionController::TestCase
  def assert_safe_response_success(result)
    if result[:error]
      flunk "Controller action failed: #{result[:error].class}: #{result[:error].message}"
    else
      assert_equal 200, result[:status], "Expected successful response"
    end
  end
end

# Include the workarounds in all test cases
class ActiveSupport::TestCase
  include ThreadErrorWorkarounds
end

class ActionController::TestCase
  include ThreadErrorWorkarounds
end