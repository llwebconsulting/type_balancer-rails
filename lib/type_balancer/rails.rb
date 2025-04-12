# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/numeric/time'
require 'active_record'
require 'active_job'
require 'redis'
require 'type_balancer'

module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    extend ActiveSupport::Autoload

    # Configuration defaults
    mattr_accessor :cache_duration, default: 1.hour
    mattr_accessor :async_threshold, default: 1000
    mattr_accessor :per_page_default, default: 25
    mattr_accessor :max_per_page, default: 100
    mattr_accessor :storage_strategy, default: :cursor

    module Strategies
      extend ActiveSupport::Autoload

      autoload :RedisStrategy, 'type_balancer/rails/strategies/redis_strategy'
      autoload :CursorStrategy, 'type_balancer/rails/strategies/cursor_strategy'
    end

    class << self
      def configure
        self.configuration ||= Configuration.new
        yield(configuration) if block_given?
        register_defaults
        self.storage_strategy = configuration.storage_strategy
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def storage_strategy=(strategy_name)
        strategy_class = StrategyRegistry.get(strategy_name)
        Container.register(:storage_strategy) { strategy_class.new }
        @storage_strategy = strategy_name
      end

      def storage_strategy
        Container.resolve(:storage_strategy)
      end

      def container
        Container
      end

      def reset!
        @configuration = Configuration.new
        Container.reset!
        StrategyRegistry.reset!
        register_defaults
      end

      private

      def register_defaults
        require_relative 'rails/strategies/redis_strategy'
        require_relative 'rails/strategies/cursor_strategy'

        # Register strategies
        StrategyRegistry.register(:redis, Strategies::RedisStrategy)
        StrategyRegistry.register(:cursor, Strategies::CursorStrategy)

        # Set initial storage strategy
        self.storage_strategy = configuration.storage_strategy
      end
    end
  end
end

require_relative 'rails/version'
require_relative 'rails/balanced_position'
require_relative 'rails/cache_invalidation'
require_relative 'rails/balance_calculation_job'
require_relative 'rails/balanced_collection_query'
require_relative 'rails/container'
require_relative 'rails/strategy_registry'
require_relative 'rails/configuration'

# Register defaults on load
TypeBalancer::Rails.reset!

# Include CacheInvalidation in ActiveRecord::Base for testing
ActiveRecord::Base.include TypeBalancer::Rails::CacheInvalidation
