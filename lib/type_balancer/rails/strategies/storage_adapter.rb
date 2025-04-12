# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Adapter for storage strategies
      class StorageAdapter
        def initialize(strategy_manager)
          @strategy_manager = strategy_manager
          @adapter = nil
        end

        attr_accessor :adapter
        attr_reader :strategy_manager

        def configure_redis(client = nil, &)
          if block_given?
            yield(redis_client)
          else
            @redis_client = client
          end
        end

        def configure_cache(store = nil, &)
          if block_given?
            yield(cache_store)
          else
            @cache_store = store
          end
        end

        def redis_client
          @redis_client ||= ::Redis.new
        end

        def cache_store
          @cache_store ||= ::Rails.cache
        end

        def redis_enabled?
          !redis_client.nil?
        end

        def reset!
          @redis_client = nil
          @cache_store = nil
          @adapter = nil
        end
      end
    end
  end
end
