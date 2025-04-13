# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Adapter for storage strategies
      class StorageAdapter
        attr_reader :strategy_manager, :adapter, :cache_ttl

        def initialize(strategy_manager = nil)
          @strategy_manager = strategy_manager
          @redis_client = nil
          @cache_store = nil
          @cache_ttl = 3600 # Default 1 hour TTL
        end

        def configure_redis(client = nil)
          if block_given?
            yield redis_client
          else
            @redis_client = client || ::Redis.new
          end
          self
        end

        def configure_cache(store = nil)
          if block_given?
            yield cache_store
          else
            @cache_store = store || ::Rails.cache
          end
          self
        end

        def redis_client
          @redis_client ||= ::Redis.new
        end

        def cache_store
          @cache_store ||= ::Rails.cache
        end

        def redis_enabled?
          !@redis_client.nil?
        end

        def cache_enabled?
          !@cache_store.nil?
        end

        def reset!
          @redis_client = nil
          @cache_store = nil
          @adapter = nil
          @cache_ttl = 3600
          self
        end
      end
    end
  end
end
