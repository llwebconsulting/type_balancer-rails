# frozen_string_literal: true

module TypeBalancer
  module Rails
    module StrategyRegistry
      class << self
        def register(name, strategy)
          strategies[name] = strategy
        end

        def resolve(name)
          strategies[name] || raise(ArgumentError, "Unknown strategy: #{name}")
        end
        alias get resolve

        def reset!
          @strategies = nil
          register_defaults
        end

        def available_strategies
          strategies.keys
        end

        private

        def strategies
          @strategies ||= {}
        end

        def register_defaults
          require_relative 'strategies/base_strategy'
          require_relative 'strategies/redis_strategy'
          require_relative 'strategies/cursor_strategy'

          register(:redis, Strategies::RedisStrategy)
          register(:cursor, Strategies::CursorStrategy)
        end
      end

      class UnknownStrategyError < StandardError; end
    end
  end
end
