require 'test_helper'

# ShadowsController doesn't exist - Shadow is STI base class
# Subclasses (Philosopher, Work) have their own controllers
class ShadowsControllerTest < ActionController::TestCase
  test "controller does not exist" do
    skip "ShadowsController does not exist - use PhilosophersController or WorksController instead"
  end
end
