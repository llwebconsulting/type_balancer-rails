# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'type_balancer'

# Core functionality
require 'type_balancer/rails/version'
require 'type_balancer/rails/errors'
require 'type_balancer/rails/core'
require 'type_balancer/rails/config'
require 'type_balancer/rails/container'

# Configuration and setup
require 'type_balancer/rails/configuration_facade'
require 'type_balancer/rails/storage_strategies'
require 'type_balancer/rails/strategies'

# ActiveRecord integration
require 'type_balancer/rails/active_record_extension'
require 'type_balancer/rails/cache_invalidation'
require 'type_balancer/rails/pagination'

# Query handling
require 'type_balancer/rails/query'
require 'type_balancer/rails/position_manager'
require 'type_balancer/rails/type_balancer_collection'

# Background processing
require 'type_balancer/rails/application_job'
require 'type_balancer/rails/balance_calculation_job'
require 'type_balancer/rails/background_processor'

# Rails integration
require 'type_balancer/rails/railtie' if defined?(Rails)

# Extend the base TypeBalancer gem with Rails integration
module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    class Error < StandardError; end

    # Configuration class for TypeBalancer Rails
    class Configuration
      include ActiveSupport::Configurable

      config_accessor :enable_redis, default: false
      config_accessor :enable_cache, default: false
      config_accessor :max_per_page, default: 100
      config_accessor :cursor_buffer_multiplier, default: 2
      config_accessor :redis_client
      config_accessor :cache_store
      config_accessor :redis_ttl, default: 3600
      config_accessor :cache_ttl, default: 3600
      config_accessor :storage_strategy, default: :cursor
      config_accessor :background_threshold, default: 1000

      attr_accessor :redis_url, :redis_options, :cache_options

      def initialize
        @strategies = {}
        @redis_options = {}
        @cache_options = {}
        super
      end

      def register_strategy(name, strategy_class)
        @strategies[name.to_sym] = strategy_class
      end

      def get_strategy(name)
        @strategies[name.to_sym]
      end

      def strategies
        @strategies.keys
      end

      def configure_redis
        yield self if block_given?
        setup_redis_client
      end

      def configure_cache
        yield self if block_given?
        setup_cache_store
      end

      private

      def setup_redis_client
        return unless enable_redis

        require 'redis'
        @redis_client = Redis.new({
          url: redis_url
        }.merge(redis_options))
      end

      def setup_cache_store
        return unless enable_cache

        @cache_store = ActiveSupport::Cache::MemoryStore.new(cache_options)
      end
    end

    class << self
      def configure
        yield configuration if block_given?
        self
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def reset!
        @configuration = nil
      end

      def initialize!
        # Register default strategies
        configuration.register_strategy(:cursor, TypeBalancer::Rails::Strategies::CursorStrategy)
        configuration.register_strategy(:redis, TypeBalancer::Rails::Strategies::RedisStrategy)

        # Set default strategy
        configuration.storage_strategy = :cursor

        # Configure cache settings
        configuration.enable_cache = true
        configuration.cache_ttl = 3600 # 1 hour default

        # Include the ActiveRecord extension
        ActiveSupport.on_load(:active_record) do
          include TypeBalancer::Rails::ActiveRecordExtension
        end
      end
      alias load! initialize! # For backward compatibility
    end
  end
end
