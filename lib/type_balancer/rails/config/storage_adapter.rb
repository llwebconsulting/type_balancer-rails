module TypeBalancer
  module Rails
    module Config
      class StorageAdapter
        attr_reader :redis_client, :cache_store

        def initialize(strategy_manager)
          @strategy_manager = strategy_manager
          @redis_client = nil
          @cache_store = nil
        end

        def store(key:, value:, ttl: nil)
          validate!
          if redis_enabled?
            store_in_redis(key, value, ttl)
          else
            store_in_cache(key, value, ttl)
          end
        end

        def fetch(key:)
          validate!
          if redis_enabled?
            fetch_from_redis(key)
          else
            fetch_from_cache(key)
          end
        end

        def configure_redis(client)
          return self unless client

          @redis_client = client
          validate_redis!
          @strategy_manager[:redis].configure_redis(client) if @strategy_manager
          self
        end

        def configure_cache(store)
          return self unless store

          @cache_store = store
          validate_cache!
          self
        end

        def validate!
          validate_strategy_manager!
          validate_redis! if redis_enabled?
          validate_cache! if cache_enabled?
          true
        end

        def clear
          if redis_enabled?
            clear_redis
          else
            clear_cache
          end
        end

        def redis_enabled?
          !@redis_client.nil?
        end

        def cache_enabled?
          !@cache_store.nil?
        end

        private

        def validate_strategy_manager!
          raise Errors::ConfigurationError, 'Strategy manager is not configured' if @strategy_manager.nil?

          @strategy_manager.validate!
        end

        def validate_redis!
          raise Errors::RedisError, 'Redis client is not configured' if @redis_client.nil?
          raise Errors::RedisError, 'Redis client is not responding' unless @redis_client.ping == 'PONG'
        rescue StandardError => e
          raise Errors::RedisError, "Redis validation failed: #{e.message}"
        end

        def validate_cache!
          raise Errors::CacheError, 'Cache store is not configured' if @cache_store.nil?

          @cache_store.read('test_key')
        rescue StandardError => e
          raise Errors::CacheError, "Cache validation failed: #{e.message}"
        end

        def store_in_redis(key, value, ttl)
          if ttl
            @redis_client.set(key, value.to_json, ex: ttl)
          else
            @redis_client.set(key, value.to_json)
          end
          value
        end

        def store_in_cache(key, value, ttl)
          if ttl
            @cache_store.write(key, value, expires_in: ttl)
          else
            @cache_store.write(key, value)
          end
          value
        end

        def fetch_from_redis(key)
          value = @redis_client.get(key)
          value ? JSON.parse(value, symbolize_names: true) : nil
        end

        def fetch_from_cache(key)
          @cache_store.read(key)
        end

        def clear_redis
          @redis_client.flushdb
        end

        def clear_cache
          @cache_store.clear
        end
      end
    end
  end
end
