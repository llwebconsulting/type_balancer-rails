# frozen_string_literal: true

require 'rails'
require 'active_record/railtie'
require 'active_support/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_job/railtie'
require 'action_cable/engine'

# Add the lib directory to the load path
$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)
require 'type_balancer_rails'

module Dummy
  class Application < Rails::Application
    # Ensure Rails.root points at spec/dummy
    config.root = File.expand_path('..', __dir__)

    # Tell Rails where to find database.yml
    config.paths['config/database'] = Rails.root.join('config/database.yml')

    config.load_defaults Rails::VERSION::STRING.to_f

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    config.api_only = true

    # Eager load paths
    config.eager_load_paths << Rails.root.join('app/models')

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Use test configuration
    config.cache_classes = true
    config.eager_load = false
    config.consider_all_requests_local = true
    config.action_controller.perform_caching = true
    config.action_dispatch.show_exceptions = false
    config.action_controller.allow_forgery_protection = false
    config.active_support.deprecation = :stderr
    config.active_support.disallowed_deprecation = :raise
    config.active_support.disallowed_deprecation_warnings = []

    # Configure ActiveJob
    config.active_job.queue_adapter = :test

    # Enable/disable features
    config.type_balancer = ActiveSupport::OrderedOptions.new
    config.type_balancer.enable_redis = true
    config.type_balancer.enable_cache = true
    config.type_balancer.max_per_page = 100
    config.type_balancer.cursor_buffer_multiplier = 2
    config.type_balancer.redis_enabled = true

    # Use memory store for testing
    config.cache_store = :memory_store, {
      namespace: 'type_balancer_test',
      size: 32.megabytes
    }
  end
end
