# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      # Manages registration and resolution of storage strategies
      class StrategyManager
        class << self
          def register(name, strategy)
            validate_strategy!(strategy)
            strategies[name.to_sym] = strategy
          end

          def resolve(name)
            name = name.to_sym
            strategies[name] || raise(UnknownStrategyError, "Unknown strategy: #{name}")
          end

          def available_strategies
            strategies.keys
          end

          def reset!
            @strategies = nil
          end

          private

          def strategies
            @strategies ||= {}
          end

          def validate_strategy!(strategy)
            return if strategy.ancestors.include?(TypeBalancer::Rails::Storage::BaseStorage)

            raise InvalidStrategyError,
                  'Strategy must inherit from TypeBalancer::Rails::Storage::BaseStorage'
          end
        end

        class UnknownStrategyError < StandardError; end
        class InvalidStrategyError < StandardError; end
      end
    end
  end
end
