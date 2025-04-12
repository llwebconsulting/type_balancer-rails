# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      # Manages storage backend configuration and initialization
      class StorageAdapter
        class << self
          attr_reader :redis_client, :cache_store

          def configure_redis(client)
            validate_redis_client!(client)
            @redis_client = client
            @redis_enabled = true
          end

          def configure_cache(store)
            validate_cache_store!(store)
            @cache_store = store
          end

          def redis_enabled?
            @redis_enabled && @redis_client.present?
          end

          def reset!
            @redis_client = nil
            @cache_store = nil
            @redis_enabled = false
          end

          private

          def validate_redis_client!(client)
            required_methods = %i[get set setex del flushdb]
            missing_methods = required_methods.reject { |method| client.respond_to?(method) }

            return if missing_methods.empty?

            raise InvalidRedisClientError,
                  "Redis client must respond to: #{missing_methods.join(', ')}"
          end

          def validate_cache_store!(store)
            required_methods = %i[read write delete clear]
            missing_methods = required_methods.reject { |method| store.respond_to?(method) }

            return if missing_methods.empty?

            raise InvalidCacheStoreError,
                  "Cache store must respond to: #{missing_methods.join(', ')}"
          end
        end

        class InvalidRedisClientError < StandardError; end
        class InvalidCacheStoreError < StandardError; end
      end
    end
  end
end
