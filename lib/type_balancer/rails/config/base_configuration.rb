# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      class BaseConfiguration
        require_relative 'strategy_manager'
        require_relative 'pagination_config'
        require_relative 'storage_adapter'
        require_relative 'validation_behavior'

        include ValidationBehavior

        attr_accessor :redis_client, :redis_ttl, :cache_ttl, :cache_store,
                      :storage_strategy, :cursor_buffer_multiplier,
                      :async_threshold, :per_page_default, :cache_duration
        attr_reader :strategy_manager, :storage_adapter, :storage_strategy_registry,
                    :pagination_config, :redis_enabled, :cache_enabled

        def initialize
          @redis_enabled = false
          @cache_enabled = false
          @cursor_buffer_multiplier = 2
          @storage_strategy_registry = TypeBalancer::Rails::Config::StrategyManager.new
          @pagination_config = TypeBalancer::Rails::Config::PaginationConfig.new
          register_default_storage_strategies
        end

        delegate :register_strategy, to: :TypeBalancer

        def redis_enabled?
          @redis_enabled
        end

        def cache_enabled?
          @cache_enabled
        end

        def enable_redis(client = nil)
          @redis_enabled = true
          @redis_client = client if client
          self
        end

        def disable_redis
          @redis_enabled = false
          @redis_client = nil
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

        def reset!
          @redis_enabled = false
          @cache_enabled = false
          @redis_client = nil
          @redis_ttl = nil
          @cache_store = nil
          @cache_ttl = nil
          @storage_strategy = nil
          @cursor_buffer_multiplier = 2
          @async_threshold = nil
          @per_page_default = nil
          @cache_duration = nil
          @storage_strategy_registry = TypeBalancer::Rails::Config::StrategyManager.new
          @pagination_config = TypeBalancer::Rails::Config::PaginationConfig.new
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

        delegate :max_per_page=, to: :@pagination_config
        delegate :max_per_page, to: :@pagination_config

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

        private

        def register_default_storage_strategies
          @storage_strategy_registry.register(:memory, TypeBalancer::Rails::Strategies::MemoryStrategy)
          @storage_strategy_registry.register(:redis, TypeBalancer::Rails::Strategies::RedisStrategy)
        end
      end
    end
  end
end
