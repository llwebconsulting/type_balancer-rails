# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Redis-based storage strategy
      class RedisStrategy < BaseStrategy
        def initialize
          super
          @redis = TypeBalancer::Rails.configuration.redis_client
          @redis_ttl = TypeBalancer::Rails.configuration.redis_ttl
        end

        def store(key, value, ttl = nil)
          validate_key!(key)
          validate_value!(value)
          key = cache_key(key)
          ttl = normalize_ttl(ttl)

          if ttl && ttl > 0
            @redis.setex(key, ttl.to_i, Marshal.dump(value))
          else
            @redis.set(key, Marshal.dump(value))
          end
        end

        def fetch(key)
          validate_key!(key)
          key = cache_key(key)
          value = @redis.get(key)
          value ? Marshal.load(value) : nil
        end

        def delete(key)
          validate_key!(key)
          @redis.del(cache_key(key))
        end

        def clear
          @redis.flushdb
        end
      end
    end
  end
end
