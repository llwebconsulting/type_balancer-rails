# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Configuration
      # Registry for storage strategies
      class StorageStrategyRegistry
        def initialize
          @strategies = {}
        end

        def register(name, strategy)
          @strategies[name.to_sym] = strategy
        end

        def resolve(name)
          @strategies[name.to_sym] || raise(KeyError, "Unknown storage strategy: #{name}")
        end

        def registered_strategies
          @strategies.keys
        end

        def reset!
          @strategies = {}
        end
      end
    end
  end
end
