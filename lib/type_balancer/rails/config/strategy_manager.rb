# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      class StrategyManager
        attr_reader :strategies

        def initialize
          @strategies = {}
          register_defaults
        end

        def register(name, strategy)
          validate_strategy!(strategy)
          @strategies[name.to_sym] = strategy
          self
        end

        def [](name)
          @strategies[name.to_sym]
        end

        def reset!
          @strategies.clear
          register_defaults
          self
        end

        def validate!
          raise TypeBalancer::Rails::Errors::ConfigurationError, 'No strategies registered' if @strategies.empty?

          @strategies.each_value { |strategy| validate_strategy!(strategy) }
          true
        end

        private

        def register_defaults
          register(:redis, Strategies::RedisStrategy.new)
          register(:memory, Strategies::MemoryStrategy.new)
        end

        def validate_strategy!(strategy)
          return if strategy.respond_to?(:store) && strategy.respond_to?(:fetch)

          raise TypeBalancer::Rails::Errors::ConfigurationError, 'Strategy must implement store and fetch methods'
        end
      end
    end
  end
end
