require 'test_helper'

class WelcomeControllerTest < ActionController::TestCase
  # WelcomeController exists but has no route — 'get welcome' maps to pages#welcome.
  # This controller appears to be dead code.
  test "welcome controller class exists" do
    assert defined?(WelcomeController)
    assert WelcomeController < ApplicationController
  end
end
