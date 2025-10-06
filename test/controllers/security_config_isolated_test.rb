require 'test_helper'

# Isolated test for SecurityConfig functionality only
class SecurityConfigIsolatedTest < ActiveSupport::TestCase
  
  def test_security_config_method_validation
    # Test that SecurityConfig can validate methods without controller context
    assert_nothing_raised do
      SecurityConfig.validate_method_call('schools')
    end
    
    assert_raises(SecurityError) do
      SecurityConfig.validate_method_call('system')
    end
    
    assert_raises(SecurityError) do
      SecurityConfig.validate_method_call('eval')
    end
  end
  
  def test_security_config_file_validation
    # Test file ID validation without controller context
    assert_equal 'test123', SecurityConfig.validate_file_id('test123')
    assert_equal 'file.txt', SecurityConfig.validate_file_id('file.txt')
    
    assert_raises(ArgumentError) do
      SecurityConfig.validate_file_id('../../../etc/passwd')
    end
    
    assert_raises(ArgumentError) do
      SecurityConfig.validate_file_id('path/traversal')
    end
  end
end