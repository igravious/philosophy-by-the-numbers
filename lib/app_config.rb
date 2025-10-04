require 'yaml'

module AppConfig
  # Read application configuration constants from config.ru YAML doc comment
  # Returns a hash of configuration values or empty hash if parsing fails
  def self.load_constants
    config_ru_path = Rails.root.join('config.ru')
    return {} unless File.exist?(config_ru_path)
    
    config_content = File.read(config_ru_path)
    
    # Extract YAML configuration from the doc comment
    yaml_match = config_content.match(/=begin\nApp Configuration Constants \(YAML format\):\n---\n(.*?)\n=end/m)
    
    if yaml_match
      begin
        YAML.load(yaml_match[1]) || {}
      rescue => e
        Rails.logger.warn "Failed to parse app config from config.ru: #{e.message}" if defined?(Rails.logger)
        {}
      end
    else
      {}
    end
  end
  
  # Get a specific configuration value with optional fallback
  def self.get(key, fallback = nil)
    @config_cache ||= load_constants
    @config_cache[key.to_s] || fallback
  end
  
  # Clear the cache (useful for testing or if config.ru changes)
  def self.reload!
    @config_cache = nil
  end
end