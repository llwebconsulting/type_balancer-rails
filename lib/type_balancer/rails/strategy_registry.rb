# frozen_string_literal: true

module TypeBalancer
  module Rails
    class StrategyRegistry
      class << self
        def register(name, strategy_class)
          strategies[name] = strategy_class
        end

        def resolve(name)
          strategies[name] || raise(ArgumentError, "Unknown strategy: #{name}")
        end

        def reset!
          @strategies = {}
        end

        private

        def strategies
          @strategies ||= {}
        end
      end
    end
  end
end
