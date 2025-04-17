# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      class RuntimeConfiguration < BaseConfiguration
        include ValidationBehavior

        attr_accessor :redis_client, :cache_ttl, :redis_ttl
        attr_reader :strategy_manager, :storage_adapter, :redis_enabled, :cache_enabled

        def initialize
          super
          @redis_enabled = true
          @cache_enabled = true
          @cache_ttl = 3600
          @redis_ttl = 3600
          setup_managers
        end

        def configure_redis(client = nil)
          @redis_client = client if client
          raise TypeBalancer::Rails::Errors::RedisError, 'Redis client is not configured' if @redis_client.nil?

          @storage_adapter.configure_redis(@redis_client)
          yield @redis_client if block_given?
          validate!
          self
        end

        def configure_cache
          cache_store = ::Rails.cache
          raise TypeBalancer::Rails::Errors::CacheError, 'Cache store is not configured' if cache_store.nil?

          @storage_adapter.configure_cache(cache_store)
          yield cache_store if block_given?
          validate!
          self
        end

        def reset!
          super
          setup_managers
          self
        end

        def validate!
          validate_strategy_manager!
          validate_storage_adapter!
          validate_cache_ttl! if cache_enabled?
          validate_redis_ttl! if redis_enabled?
          true
        end

        private

        def setup_managers
          @strategy_manager = TypeBalancer::Rails::Config::StrategyManager.new
          @storage_adapter = TypeBalancer::Rails::Config::ConfigStorageAdapter.new(@strategy_manager)
        end

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
          if @strategy_manager.nil?
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Strategy manager is not configured'
          end

          @strategy_manager.validate!
        end

        def validate_storage_adapter!
          if @storage_adapter.nil?
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Storage adapter is not configured'
          end

          @storage_adapter.validate!
        end
      end
    end
  end
end
