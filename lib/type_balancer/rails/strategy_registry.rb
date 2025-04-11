module TypeBalancer
  module Rails
    class StrategyRegistry
      class << self
        def register(name, strategy_class)
          strategies[name] = strategy_class
        end

        def get(name)
          strategies[name] || raise(ArgumentError, "Unknown storage strategy: #{name}")
        end

        def strategies
          @strategies ||= {}
        end

        def reset!
          @strategies = {}
        end
      end
    end
  end
end 