
require_relative '../../lib/app_config'

# Set relative_url_root using the RELATIVE_URL_ROOT constant from config.ru
Rails.application.config.relative_url_root = AppConfig.get('RELATIVE_URL_ROOT')
