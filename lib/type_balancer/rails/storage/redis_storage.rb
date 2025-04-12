# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Storage
      # Redis-based storage implementation
      class RedisStorage < BaseStorage
        def initialize(options = {})
          super
          @redis = options[:redis] || TypeBalancer::Rails.configuration.redis_client
          raise ArgumentError, 'Redis client not configured' unless @redis
        end

        def store(key, value, ttl = nil)
          validate_key!(key)
          validate_value!(value)
          validate_ttl!(ttl) if ttl

          serialized_value = serialize(value)
          if ttl
            redis.setex(storage_key(key), ttl, serialized_value)
          else
            redis.set(storage_key(key), serialized_value)
          end

          value
        end

        def fetch(key)
          validate_key!(key)

          serialized_value = redis.get(storage_key(key))
          return nil unless serialized_value

          deserialize(serialized_value)
        end

        def delete(key)
          validate_key!(key)
          redis.del(storage_key(key))
        end

        def clear
          keys = redis.keys("#{key_prefix}*")
          redis.del(*keys) unless keys.empty?
        end

        private

        attr_reader :redis

        def key_prefix
          'type_balancer:rails:'
        end

        def storage_key(key)
          "#{key_prefix}#{key}"
        end

        def serialize(value)
          Marshal.dump(value)
        end

        def deserialize(value)
          Marshal.load(value)
        rescue StandardError
          nil
        end
      end
    end
  end
end
