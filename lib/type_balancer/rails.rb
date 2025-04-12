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
require_relative 'rails/balanced_position'
require_relative 'rails/cache_invalidation'
require_relative 'rails/balance_calculation_job'
require_relative 'rails/balanced_collection_query'
require_relative 'rails/container'
require_relative 'rails/storage_strategies'
require_relative 'rails/strategies/storage_strategy_registry'
require_relative 'rails/strategies/storage_adapter'
require_relative 'rails/railtie' if defined?(Rails)
require_relative 'rails/configuration'

module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    extend ActiveSupport::Autoload
    extend ActiveSupport::Concern
    include Core::ConfigurationFacade

    class << self
      delegate :configuration, :configure, :reset!, to: Core

      delegate :strategy_manager, to: :configuration

      delegate :storage_adapter, to: :configuration

      def initialize!
        register_defaults
        reset!
        self
      end

      def register_defaults
        register_storage_strategies
        configure_cache_defaults
        self
      end

      def register_strategy(name, strategy_class)
        strategy_manager.register(name, strategy_class)
        self
      end

      def resolve_strategy(name)
        strategy_manager.resolve(name)
      end

      def configure_redis(&)
        configuration.redis_client = yield if block_given?
        self
      end

      def configure_cache(&)
        configuration.cache_store = yield if block_given?
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

      private

      def register_storage_strategies
        configure do |config|
          config.strategy_manager = TypeBalancer::Rails::Strategies::StorageStrategyRegistry.new
          config.storage_adapter = TypeBalancer::Rails::Strategies::StorageAdapter.new(config.strategy_manager)
        end
      end

      def configure_cache_defaults
        configure do |config|
          config.configure_cache do |cache|
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
