module SecurityConfig
  # Whitelisted methods for dynamic dispatch in controllers
  ALLOWED_QUESTION_METHODS = %w[
    schools interests subjects birth_places death_places 
    instances languages places countries influences
    dumb_irish irish dumb_countries countries all_countries
    dumb_languages languages all_places
  ].freeze
  
  # File upload restrictions
  MAX_FILE_SIZE = 10.megabytes
  ALLOWED_FILE_EXTENSIONS = %w[.txt .json .csv].freeze
  
  # Path validation for file serving
  def self.validate_file_id(file_id)
    file_id = file_id.to_s.strip
    
    # Only allow alphanumeric characters, dots, underscores, and hyphens
    unless file_id.match?(/\A[a-zA-Z0-9._-]+\z/)
      raise ArgumentError, "Invalid file ID format: contains illegal characters"
    end
    
    # Prevent directory traversal
    if file_id.include?('..') || file_id.include?('/') || file_id.include?('\\')
      raise ArgumentError, "File ID cannot contain path separators or parent directory references"
    end
    
    # Prevent access to hidden files
    if file_id.start_with?('.')
      raise ArgumentError, "Access to hidden files is not allowed"
    end
    
    file_id
  end
  
  # Method validation for dynamic dispatch
  def self.validate_method_call(method_name, allowed_methods = ALLOWED_QUESTION_METHODS)
    method_name = method_name.to_s.strip
    
    unless allowed_methods.include?(method_name)
      raise SecurityError, "Method '#{method_name}' is not in the allowed methods list"
    end
    
    method_name
  end
  
  # Safe credential loading
  def self.load_credential(credential_name, file_path = nil)
    # First try environment variable
    env_value = ENV[credential_name]
    return env_value if env_value && !env_value.empty?
    
    # Then try file-based credential
    if file_path
      credential_file = Rails.root.join(file_path)
      if File.exist?(credential_file)
        return File.read(credential_file).strip
      end
    end
    
    raise "Credential '#{credential_name}' not found in environment or file"
  end
end