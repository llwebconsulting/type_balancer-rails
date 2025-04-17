# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      class Configuration < BaseConfiguration
        include ValidationBehavior
        include StorageManagement

        attr_accessor :redis_client, :cache_ttl, :redis_ttl, :per_page
        attr_reader :strategy_manager, :storage_adapter, :redis_enabled, :cache_enabled,
                    :storage_strategy_registry, :pagination_config

        def initialize
          super
          @redis_enabled = false
          @cache_enabled = false
          @redis_ttl = nil
          @cache_ttl = nil
          @per_page = 25
          setup_storage
          @storage_strategy_registry = TypeBalancer::Rails::Configuration::StorageStrategyRegistry.new
          @pagination_config = TypeBalancer::Rails::Configuration::PaginationConfig.new
          reset!
        end

        def configure
          yield self if block_given?
          self
        end

        def configure_redis(client)
          @redis_client = client
          @storage_adapter.configure_redis(@redis_client)
          self
        end

        def configure_cache(store)
          @storage_adapter.configure_cache(store)
          self
        end

        def reset!
          @redis_client = nil
          @cache_ttl = nil
          @redis_ttl = nil
          @redis_enabled = false
          @cache_enabled = false
          setup_storage
          @storage_strategy_registry = TypeBalancer::Rails::Configuration::StorageStrategyRegistry.new
          @pagination_config.reset!
          self
        end

        def redis_settings
          {
            enabled: @redis_enabled,
            client: @redis_client,
            ttl: @redis_ttl
          }
        end

        def cache_settings
          {
            enabled: @cache_enabled,
            store: ::Rails.cache,
            ttl: @cache_ttl
          }
        end

        def storage_settings
          {
            strategy: @storage_strategy
          }
        end

        def pagination_settings
          {
            max_per_page: @pagination_config.max_per_page,
            cursor_buffer_multiplier: @cursor_buffer_multiplier
          }
        end

        def enable_redis
          @redis_enabled = true
        end

        def disable_redis
          @redis_enabled = false
        end

        def redis_enabled?
          @redis_enabled
        end

        def enable_cache
          @cache_enabled = true
        end

        def disable_cache
          @cache_enabled = false
        end

        def cache_enabled?
          @cache_enabled
        end

        def redis(&block)
          yield(self) if block
          self
        end

        def cache(&block)
          yield(self) if block
          self
        end

        def pagination(&block)
          yield(@pagination_config) if block
          self
        end

        private

        def register_default_storage_strategies
          @storage_strategy_registry.register(:memory, TypeBalancer::Rails::Strategies::MemoryStrategy)
          @storage_strategy_registry.register(:redis, TypeBalancer::Rails::Strategies::RedisStrategy)
        end
      end
    end
  end
end
