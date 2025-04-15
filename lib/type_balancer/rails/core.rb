# frozen_string_literal: true

require 'active_support'
require 'type_balancer/rails/config/storage_adapter'

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
            @configuration ||= Configuration.new
          end

          def reset!
            @configuration = Configuration.new
            self
          end
        end
      end

      extend ConfigurationFacade::ClassMethods

      class Configuration
        attr_accessor :redis_client, :cache_ttl, :redis_ttl
        attr_reader :strategy_manager, :storage_adapter, :redis_enabled, :cache_enabled

        def initialize
          @redis_enabled = true
          @cache_enabled = true
          @cache_ttl = 3600
          @redis_ttl = 3600
          @redis_client = nil
          @strategy_manager = TypeBalancer::Rails::Config::StrategyManager.new
          @storage_adapter = TypeBalancer::Rails::Config::ConfigStorageAdapter.new(@strategy_manager)
        end

        def configure_redis(client = nil)
          @redis_client = client if client
          raise Errors::RedisError, 'Redis client is not configured' if @redis_client.nil?

          @storage_adapter.configure_redis(@redis_client)
          yield @redis_client if block_given?
          validate!
          self
        end

        def configure_cache
          cache_store = ::Rails.cache
          raise Errors::CacheError, 'Cache store is not configured' if cache_store.nil?

          @storage_adapter.configure_cache(cache_store)
          yield cache_store if block_given?
          validate!
          self
        end

        def reset!
          @redis_client = nil
          @cache_ttl = 3600
          @redis_ttl = 3600
          @strategy_manager = TypeBalancer::Rails::Config::StrategyManager.new
          @storage_adapter = TypeBalancer::Rails::Config::ConfigStorageAdapter.new(@strategy_manager)
          self
        end

        def validate!
          validate_strategy_manager!
          validate_storage_adapter!
          validate_cache_ttl!
          validate_redis_ttl!
          true
        end

        private

        def validate_cache_ttl!
          unless @cache_ttl.is_a?(Integer)
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Cache TTL must be an integer'
          end
          return if @cache_ttl.positive?

          raise TypeBalancer::Rails::Errors::ConfigurationError,
                'Cache TTL must be positive'
        end

        def validate_redis_ttl!
          unless @redis_ttl.is_a?(Integer)
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Redis TTL must be an integer'
          end
          return if @redis_ttl.positive?

          raise TypeBalancer::Rails::Errors::ConfigurationError,
                'Redis TTL must be positive'
        end

        def validate_strategy_manager!
          @strategy_manager.validate!
        rescue StandardError => e
          raise TypeBalancer::Rails::Errors::ConfigurationError, "Invalid strategy: #{e.message}"
        end

        def validate_storage_adapter!
          @storage_adapter.validate!
        rescue StandardError => e
          raise TypeBalancer::Rails::Errors::ConfigurationError, "Invalid storage: #{e.message}"
        end
      end

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
