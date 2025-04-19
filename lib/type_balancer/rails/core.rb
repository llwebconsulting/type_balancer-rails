# frozen_string_literal: true

require 'active_support'
require 'type_balancer/rails/config/storage_adapter'
require_relative 'config/base_configuration'
require_relative 'config/validation_behavior'
require_relative 'config/runtime_configuration'

module TypeBalancer
  module Rails
    # Core configuration module
    module Core
      module ConfigurationFacade
        module ClassMethods
          def configure
            yield(configuration) if block_given?
            self
          end

          def configuration
            @configuration ||= TypeBalancer::Rails::Config::RuntimeConfiguration.new
          end

          def reset!
            @configuration = TypeBalancer::Rails::Config::RuntimeConfiguration.new
            self
          end

          def initialize!
            register_defaults
            configuration.validate!
            self
          end

          def load!
            register_defaults
            ActiveSupport.on_load(:active_record) { include TypeBalancer::Rails::CacheInvalidation }
            self
          end

          private

          def register_defaults
            # Register strategies as instances with proper dependencies
            redis_strategy = TypeBalancer::Rails::Strategies::RedisStrategy.new(nil, configuration.storage_adapter)
            memory_strategy = TypeBalancer::Rails::Strategies::MemoryStrategy.new(nil, configuration.storage_adapter)
            cursor_strategy = TypeBalancer::Rails::Strategies::CursorStrategy.new(nil, configuration.storage_adapter)

            configuration.strategy_manager.register(:redis, redis_strategy)
            configuration.strategy_manager.register(:memory, memory_strategy)
            configuration.strategy_manager.register(:cursor, cursor_strategy)
          end
        end
      end

      extend ConfigurationFacade::ClassMethods

      class StorageStrategyRegistry
        def initialize
          @strategies = {}
        end

        def register(name, strategy)
          @strategies[name.to_sym] = strategy
        end

        def [](name)
          @strategies[name.to_sym]
        end

        delegate :clear, to: :@strategies
      end
    end
  end
end
