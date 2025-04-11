# frozen_string_literal: true

require "active_support"
require "active_record"
require "type_balancer"
require_relative "rails/version"
require_relative "rails/container"
require_relative "rails/strategy_registry"

module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    extend ActiveSupport::Autoload

    autoload :BalancedCollectionQuery
    autoload :BalancedPosition
    autoload :CacheInvalidation

    # Configuration class for TypeBalancer::Rails
    class Configuration
      attr_accessor :cache_duration, :async_threshold, :per_page_default, :max_per_page, :storage_strategy, :redis, :redis_ttl, :cursor_buffer_multiplier

      def initialize
        @cache_duration = 1.hour
        @async_threshold = 1000
        @per_page_default = 25
        @max_per_page = 100
      end
    end

    class << self
      def configure
        yield(configuration)
        register_default_services
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def storage_strategy
        Container.resolve(:storage_strategy)
      end

      private

      def register_default_services
        # Register strategies
        StrategyRegistry.register(:cursor, Strategies::CursorStrategy)
        StrategyRegistry.register(:redis, Strategies::RedisStrategy)

        # Register storage strategy factory
        Container.register(:storage_strategy) do
          strategy_class = StrategyRegistry.get(configuration.storage_strategy || :cursor)
          
          case strategy_class.name
          when "TypeBalancer::Rails::Strategies::RedisStrategy"
            strategy_class.new(
              redis: Container.resolve(:redis_client),
              ttl: configuration.redis_ttl
            )
          when "TypeBalancer::Rails::Strategies::CursorStrategy"
            strategy_class.new(
              buffer_multiplier: configuration.cursor_buffer_multiplier
            )
          else
            strategy_class.new
          end
        end

        # Register Redis client if configured
        Container.register(:redis_client) do
          configuration.redis || Redis.new
        end
      end
    end

    # Extend ActiveRecord with type balancing capabilities
    module ActiveRecordExtension
      extend ActiveSupport::Concern

      class_methods do
        def balance_by_type(field: nil, order: nil)
          TypeBalancer::Rails::BalancedCollectionQuery.new(
            all,
            field: field,
            order: order
          )
        end
      end
    end
  end
end

# Register default strategies
TypeBalancer::Rails::StrategyRegistry.register(:cursor, TypeBalancer::Rails::Strategies::CursorStrategy)
TypeBalancer::Rails::StrategyRegistry.register(:redis, TypeBalancer::Rails::Strategies::RedisStrategy)

# Extend ActiveRecord::Base with TypeBalancer functionality
ActiveSupport.on_load(:active_record) do
  include TypeBalancer::Rails::ActiveRecordExtension
end
