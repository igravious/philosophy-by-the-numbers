require "test_helper"
require "minitest/mock"

class RuntimeConfigurationTest < ActiveSupport::TestCase
  test "development enables diagnostics and configures the application cache" do
    config = environment_configuration("development")

    refute config.cache_classes
    refute config.eager_load
    assert config.consider_all_requests_local
    refute config.action_controller.perform_caching
    refute config.action_mailer.raise_delivery_errors
    assert_equal :log, config.active_support.deprecation
    assert_equal :page_load, config.active_record.migration_error
    assert config.assets.debug
    assert_equal [:mem_cache_store, "localhost", {namespace: "CORPUS_DEV_V1", expires_in: 1.year}], config.cache_store
  end

  test "production configures cached assets and error handling" do
    config = environment_configuration("production")

    assert config.cache_classes
    assert config.eager_load
    refute config.consider_all_requests_local
    assert config.action_controller.perform_caching
    refute config.serve_static_assets
    assert_equal :uglifier, config.assets.js_compressor
    refute config.assets.compile
    assert config.assets.digest
    assert_equal "1.0", config.assets.version
    assert_equal :info, config.log_level
    assert config.i18n.fallbacks
    assert_equal :notify, config.active_support.deprecation
    assert_instance_of Logger::Formatter, config.log_formatter
  end

  test "core extensions split and join values with explicit separators" do
    assert_equal ["Plato", "Aristotle"], "Plato;Aristotle".splat(";")
    assert_equal "Plato;Aristotle", ["Plato", "Aristotle"].unsplat(";")
  end

  test "monitor initialization is idempotent and handles the legacy thread error" do
    monitor = Monitor.new
    2.times { monitor.mon_initialize }
    assert monitor.synchronize { true }
    monitor = Monitor.allocate
    messages = []
    monitor.stub(:original_mon_initialize, -> { raise ThreadError, "already initialized" }) do
      Rails.logger.stub(:debug, ->(message) { messages << message }) { monitor.mon_initialize }
    end
    assert_includes messages.first, "Monitor already initialized"
  end

  test "response initialization recovers only from the known monitor error" do
    response = ActionDispatch::Response.allocate
    response.stub(:original_initialize, ->(*) { raise ThreadError, "already initialized" }) do
      response.send(:initialize)
      assert_equal 200, response.status
      assert_equal({}, response.headers)
      assert_equal [], response.instance_variable_get(:@body)
    end
    response.stub(:original_initialize, ->(*) { raise ThreadError, "another thread error" }) do
      assert_raises(ThreadError) { response.send(:initialize) }
    end
  end

  private

  def environment_configuration(name)
    config = ActiveSupport::OrderedOptions.new
    %i[action_controller action_mailer active_support active_record assets i18n].each do |key|
      config[key] = ActiveSupport::OrderedOptions.new
    end
    context = Struct.new(:config).new(config)
    configure = ->(&block) { context.instance_eval(&block) }
    CorpusBuilder::Application.stub(:configure, configure) do
      load Rails.root.join("config/environments/#{name}.rb")
    end
    config
  end
end
