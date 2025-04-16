module TypeBalancer
  module Rails
    module Config
      class BaseConfiguration
        require_relative 'strategy_manager'
        require_relative 'pagination_config'
        require_relative 'storage_adapter'

        attr_accessor :redis_client, :redis_enabled, :redis_ttl,
                      :cache_enabled, :cache_ttl, :cache_store,
                      :storage_strategy, :max_per_page, :cursor_buffer_multiplier,
                      :async_threshold, :per_page_default, :cache_duration
        attr_reader :strategy_manager, :storage_adapter, :storage_strategy_registry, :pagination_config

        def initialize
          @redis_enabled = false
          @cache_enabled = false
          @storage_strategy_registry = TypeBalancer::Rails::Config::StrategyManager.new
          @pagination_config = TypeBalancer::Rails::Config::PaginationConfig.new
          register_default_storage_strategies
        end

        delegate :register_strategy, to: :TypeBalancer

        def redis_enabled?
          @redis_enabled && !@redis_client.nil?
        end

        def reset!
          @redis_enabled = false
          @cache_enabled = false
          @redis_client = nil
          @storage_strategy_registry = TypeBalancer::Rails::Config::StrategyManager.new
          @pagination_config.reset!
          register_default_storage_strategies
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
            store: @cache_store,
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

        def max_per_page=(value)
          @pagination_config.set_max_per_page(value)
        end

        def redis
          yield(self) if block_given?
          self
        end

        def cache
          yield(self) if block_given?
          self
        end

        def pagination
          yield(@pagination_config) if block_given?
          self
        end

        def enable_redis(client = nil)
          @redis_enabled = true
          @redis_client = client
        end

        def disable_redis
          @redis_enabled = false
          @redis_client = nil
        end

        def enable_cache
          @cache_enabled = true
        end

        def disable_cache
          @cache_enabled = false
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
