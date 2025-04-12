# frozen_string_literal: true

require_relative 'config/configuration'
require_relative 'config/strategy_manager'
require_relative 'config/storage_adapter'

module TypeBalancer
  module Rails
    # Main configuration interface for TypeBalancer Rails
    class << self
      def configure
        yield(configuration) if block_given?
        self
      end

      def configuration
        @configuration ||= Config::Configuration.new
      end

      def strategy_manager
        Config::StrategyManager
      end

      def storage_adapter
        Config::StorageAdapter
      end

      def reset!
        @configuration = nil
        strategy_manager.reset!
        storage_adapter.reset!
      end

      def register_strategy(name, strategy)
        strategy_manager.register(name, strategy)
      end

      def resolve_strategy(name)
        strategy_manager.resolve(name)
      end

      delegate :configure_redis, to: :storage_adapter

      delegate :configure_cache, to: :storage_adapter

      delegate :redis_enabled?, to: :storage_adapter
    end
  end
end
