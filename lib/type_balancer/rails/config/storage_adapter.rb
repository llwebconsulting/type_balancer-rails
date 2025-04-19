# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      class ConfigStorageAdapter
        attr_reader :redis_client, :cache_store

        def initialize(strategy_manager)
          @strategy_manager = strategy_manager
          @redis_client = nil
          @cache_store = nil
        end

        def store(key, value, ttl = nil)
          validate!
          if redis_enabled?
            store_in_redis(key, value, ttl)
          elsif cache_enabled?
            store_in_cache(key, value, ttl)
          else
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Neither Redis nor cache store is configured'
          end
        end

        def fetch(key)
          validate!
          if redis_enabled?
            fetch_from_redis(key)
          elsif cache_enabled?
            fetch_from_cache(key)
          else
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Neither Redis nor cache store is configured'
          end
        end

        def configure_redis(client)
          return self unless client

          @redis_client = client
          validate_redis!
          redis_strategy = TypeBalancer::Rails::Strategies::RedisStrategy.new(nil, self)
          @strategy_manager.register(:redis, redis_strategy) if @strategy_manager
          self
        end

        def configure_cache(store)
          return self unless store

          @cache_store = store
          validate_cache!
          self
        end

        def validate!
          if @strategy_manager.nil?
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Strategy manager is not configured'
          end

          validate_strategy_manager!
          validate_redis! if redis_enabled?
          validate_cache! if cache_enabled?
          puts "[DEBUG] Redis enabled? #{redis_enabled?}, Cache enabled? #{cache_enabled?}"
          puts "[DEBUG] Redis client: #{@redis_client.inspect}"
          puts "[DEBUG] Cache store: #{@cache_store.inspect}"
          puts "[DEBUG] Strategies registered: #{@strategy_manager.strategies.keys.inspect}"
          true
        end

        def clear
          if redis_enabled?
            clear_redis
          elsif cache_enabled?
            clear_cache
          else
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Neither Redis nor cache store is configured'
          end
        end

        def clear_for_scope(scope)
          validate!
          if redis_enabled?
            clear_scope_in_redis(scope)
          elsif cache_enabled?
            clear_scope_in_cache(scope)
          else
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Neither Redis nor cache store is configured'
          end
        end

        def redis_enabled?
          !@redis_client.nil?
        end

        def cache_enabled?
          !@cache_store.nil?
        end

        def delete(key)
          validate!
          if redis_enabled?
            delete_from_redis(key)
          elsif cache_enabled?
            delete_from_cache(key)
          else
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Neither Redis nor cache store is configured'
          end
        end

        def exists?(key)
          validate!
          if redis_enabled?
            exists_in_redis?(key)
          elsif cache_enabled?
            exists_in_cache?(key)
          else
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Neither Redis nor cache store is configured'
          end
        end

        private

        def validate_strategy_manager!
          @strategy_manager.validate!
        end

        def validate_redis!
          raise TypeBalancer::Rails::Errors::RedisError, 'Redis client is not configured' if @redis_client.nil?

          unless @redis_client.ping == 'PONG'
            raise TypeBalancer::Rails::Errors::RedisError,
                  'Redis client is not responding'
          end
        rescue StandardError => e
          raise TypeBalancer::Rails::Errors::RedisError, "Redis validation failed: #{e.message}"
        end

        def validate_cache!
          raise TypeBalancer::Rails::Errors::CacheError, 'Cache store is not configured' if @cache_store.nil?

          @cache_store.read('test_key')
        rescue StandardError => e
          raise TypeBalancer::Rails::Errors::CacheError, "Cache validation failed: #{e.message}"
        end

        def store_in_redis(key, value, ttl)
          ttl ||= TypeBalancer::Rails.redis_ttl
          @redis_client.setex(key, ttl, value.to_json)
          value
        end

        def store_in_cache(key, value, ttl)
          ttl ||= TypeBalancer::Rails.cache_ttl
          @cache_store.write(key, value, expires_in: ttl)
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

        def clear_scope_in_redis(scope)
          pattern = "#{scope}:*"
          keys = @redis_client.keys(pattern)
          @redis_client.del(*keys) unless keys.empty?
        end

        def clear_scope_in_cache(scope)
          pattern = "#{scope}:*"
          keys = @cache_store.send(:search_for_keys, pattern)
          keys.each { |key| @cache_store.delete(key) }
        end

        def delete_from_redis(key)
          @redis_client.del(key)
        end

        def delete_from_cache(key)
          @cache_store.delete(key)
        end

        def exists_in_redis?(key)
          @redis_client.exists?(key)
        end

        def exists_in_cache?(key)
          @cache_store.exist?(key)
        end
      end
    end
  end
end
