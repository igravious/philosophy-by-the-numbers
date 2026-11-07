require 'test_helper'

class HttpRequestLoggerTest < ActiveSupport::TestCase
  test "http request logger can be created" do
    logger = HttpRequestLogger.new
    assert logger.save
  end

  test "http request logger persists attributes" do
    logger = HttpRequestLogger.create!
    assert_not_nil logger.id
    reloaded = HttpRequestLogger.find(logger.id)
    assert_equal logger.id, reloaded.id
  end

  test "http request logger can be destroyed" do
    logger = HttpRequestLogger.create!
    assert_difference 'HttpRequestLogger.count', -1 do
      logger.destroy
    end
  end
end
