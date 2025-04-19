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

        def storage_strategy=(strategy)
          @storage_strategy = strategy.to_sym
          configure_redis(@redis_client) if @storage_strategy == :redis && redis_enabled? && @redis_client
          self
        end

        def reset!
          # Store current Redis settings
          old_redis_client = @redis_client
          old_redis_enabled = @redis_enabled
          old_redis_ttl = @redis_ttl

          super
          setup_managers

          # Restore Redis settings if they were previously configured
          if old_redis_enabled && old_redis_client
            @redis_enabled = old_redis_enabled
            @redis_ttl = old_redis_ttl
            configure_redis(old_redis_client)
          end

          self
        end

        def validate!
          validate_strategy_manager!
          validate_storage_adapter!
          validate_cache_ttl! if cache_enabled?
          validate_redis_ttl! if redis_enabled?
          true
        end

        def redis(&block)
          yield(self) if block
          self
        end

        def enable_redis(client = nil)
          @redis_enabled = true
          configure_redis(client) if client
          self
        end

        def disable_redis
          @redis_enabled = false
          @redis_client = nil
          self
        end

        def redis_enabled?
          @redis_enabled && !@redis_client.nil?
        end

        def cache(&block)
          yield(self) if block
          self
        end

        def enable_cache
          @cache_enabled = true
          self
        end

        def disable_cache
          @cache_enabled = false
          self
        end

        def cache_enabled?
          @cache_enabled
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
