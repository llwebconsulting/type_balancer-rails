# frozen_string_literal: true

require 'active_support/all'
require 'active_record'
require 'active_job'
require 'redis'
require 'type_balancer'

require_relative 'rails/core'
require_relative 'rails/storage'
require_relative 'rails/query'
require_relative 'rails/version'
require_relative 'rails/cache_invalidation'
require_relative 'rails/balance_calculation_job'
require_relative 'rails/container'
require_relative 'rails/storage_strategies'
require_relative 'rails/strategies'
require_relative 'rails/strategies/storage_adapter'
require_relative 'rails/railtie' if defined?(Rails)
require_relative 'rails/configuration'
require_relative 'rails/pagination'
require_relative 'rails/position_manager'
require_relative 'rails/background_processor'
require_relative 'rails/config'
require_relative 'rails/strategies/base_strategy'
require_relative 'rails/strategies/redis_strategy'
require_relative 'rails/query/position_manager'
require_relative 'rails/active_record_extension'
require 'type_balancer/rails/errors'

module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    extend ActiveSupport::Autoload
    extend Core::ConfigurationFacade::ClassMethods

    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100
    BACKGROUND_THRESHOLD = 1000

    class << self
      delegate :configuration, :configure, :reset!, to: Core

      delegate :strategy_manager, to: :configuration

      delegate :storage_adapter, to: :configuration

      delegate :configure_redis, :configure_cache, :redis_client, :cache_ttl, :redis_ttl, to: :configuration

      def initialize!
        register_defaults
        configuration.validate!
        self
      end

      def register_defaults
        configuration.strategy_manager.register(:redis, Strategies::RedisStrategy.new)
        configuration.strategy_manager.register(:memory, Strategies::MemoryStrategy.new)
      end

      def register_strategy(name, strategy)
        strategy_manager.register(name, strategy)
        self
      end

      def resolve_strategy(name)
        strategy_manager[name]
      end

      def configure_redis(&)
        if block_given?
          configuration.configure_redis(&)
        else
          configuration.configure_redis
        end
        self
      end

      def configure_cache(&)
        if block_given?
          configuration.configure_cache(&)
        else
          configuration.configure_cache
        end
        self
      end

      def method_missing(method_name, *, &)
        if configuration.respond_to?(method_name)
          configuration.public_send(method_name, *, &)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        configuration.respond_to?(method_name, include_private) || super
      end

      def balance_collection(relation, options = {})
        Query::BalancedQuery.new(relation, options).build
      end

      def reset!
        @configuration = nil
        self
      end

      def load!
        register_defaults
        ActiveRecord::Base.include(CacheInvalidation)
        self
      end

      private

      def register_storage_strategies
        configure do |config|
          config.strategy_manager.register(:redis, Strategies::RedisStrategy.new)
          config.strategy_manager.register(:memory, Strategies::MemoryStrategy.new)
        end
      end

      def configure_cache_defaults
        configure do |config|
          config.configure_cache do |cache|
            cache.options ||= {}
            cache.options[:namespace] = 'type_balancer'
            cache.options[:expires_in] = config.cache_ttl
          end
        end
      end
    end
  end
end

# Include CacheInvalidation in ActiveRecord::Base for testing
ActiveRecord::Base.include TypeBalancer::Rails::CacheInvalidation

TypeBalancer::Rails.load!
