module TypeBalancer
  module Rails
    class Configuration
      require_relative 'configuration/storage_strategy_registry'

      attr_accessor :redis_client, :redis_enabled, :redis_ttl,
                    :cache_enabled, :cache_ttl, :cache_store,
                    :storage_strategy, :max_per_page, :cursor_buffer_multiplier,
                    :async_threshold, :per_page_default, :cache_duration
      attr_reader :strategy_manager, :storage_adapter

      class StorageAdapter
        def initialize
          @adapter = nil
        end

        attr_accessor :adapter
      end

      def initialize
        @redis_enabled = true
        @cache_enabled = true
        @cache_ttl = 3600 # 1 hour default
        @storage_strategy = :redis
        @strategy_manager = TypeBalancer::Rails::Configuration::StorageStrategyRegistry.new
        @storage_adapter = StorageAdapter.new
        register_default_strategies
        reset!
      end

      delegate :register_strategy, to: :TypeBalancer

      def redis_enabled?
        @redis_enabled && !@redis_client.nil?
      end

      def reset!
        @redis_ttl = 3600 # 1 hour default
        @cache_store = nil
        @max_per_page = 100
        @cursor_buffer_multiplier = 1.5
        @async_threshold = BackgroundProcessor::DEFAULT_ASYNC_THRESHOLD
        @per_page_default = Pagination::DEFAULT_PER_PAGE
        @cache_duration = 1.hour
        self
      end

      def redis_settings
        {
          enabled: redis_enabled?,
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
          max_per_page: @max_per_page,
          cursor_buffer_multiplier: @cursor_buffer_multiplier
        }
      end

      def configure_redis(&)
        yield @redis_client if block_given?
        self
      end

      def configure_cache(&)
        yield ::Rails.cache if block_given?
        self
      end

      private

      def register_default_strategies
        strategy_manager.register(:redis, Strategies::RedisStrategy)
        strategy_manager.register(:cursor, Strategies::CursorStrategy)
      end
    end
  end
end
