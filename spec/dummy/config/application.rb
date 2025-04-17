# frozen_string_literal: true

require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'type_balancer-rails'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # Settings in config/environments/* take precedence over those specified here.
    config.cache_classes = true
    config.eager_load = false
    config.active_support.deprecation = :stderr
    config.active_support.test_order = :random
    config.action_controller.allow_forgery_protection = false
    config.action_controller.perform_caching = true

    # Database configuration
    config.active_record.sqlite3.represent_boolean_as_integer = true
    config.active_record.maintain_test_schema = false

    # Redis configuration for caching
    config.cache_store = :redis_cache_store, {
      url: ENV['REDIS_URL'] || 'redis://localhost:6379/1',
      error_handler: lambda { |method:, returning:, exception:|
        Rails.logger.error "Redis cache error: #{exception.class}: #{exception.message}"
      }
    }

    # Enable/disable features
    config.type_balancer.enable_redis = true
    config.type_balancer.enable_cache = true
    config.type_balancer.max_per_page = 100
    config.type_balancer.cursor_buffer_multiplier = 2
  end
end
