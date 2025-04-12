# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Registry for storage strategies
      class StorageStrategyRegistry
        def initialize
          @strategies = {}
        end

        def register(name, strategy)
          @strategies[name.to_sym] = strategy
        end

        def resolve(name)
          strategy = @strategies[name.to_sym]
          raise KeyError, "Unknown storage strategy: #{name}" unless strategy

          strategy
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
