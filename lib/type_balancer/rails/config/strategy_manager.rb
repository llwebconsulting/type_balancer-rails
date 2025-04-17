# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      class StrategyManager
        attr_reader :strategies, :strategy_classes

        def initialize
          @strategies = {}
          @strategy_classes = {}
          register_default_classes
        end

        def register(name, strategy)
          validate_strategy!(strategy)
          @strategies[name.to_sym] = strategy
          self
        end

        def register_class(name, strategy_class)
          @strategy_classes[name.to_sym] = strategy_class
          self
        end

        def [](name)
          name = name.to_sym
          @strategies[name] ||= create_strategy(name)
        end

        def reset!
          @strategies.clear
          @strategy_classes.clear
          register_default_classes
          self
        end

        def validate!
          raise TypeBalancer::Rails::Errors::ConfigurationError, 'No strategies registered' if @strategy_classes.empty?

          @strategies.each_value { |strategy| validate_strategy!(strategy) }
          true
        end

        private

        def register_default_classes
          register_class(:redis, Strategies::RedisStrategy)
          register_class(:memory, Strategies::MemoryStrategy)
        end

        def create_strategy(name)
          strategy_class = @strategy_classes[name]
          raise TypeBalancer::Rails::Errors::ConfigurationError, "Unknown strategy: #{name}" unless strategy_class

          strategy = strategy_class.new
          validate_strategy!(strategy)
          strategy
        end

        def validate_strategy!(strategy)
          return if strategy.respond_to?(:store) && strategy.respond_to?(:fetch)

          raise TypeBalancer::Rails::Errors::ConfigurationError, 'Strategy must implement store and fetch methods'
        end
      end
    end
  end
end
