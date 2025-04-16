# frozen_string_literal: true

require 'json'

module TypeBalancer
  module Rails
    module Strategies
      # Redis-based storage strategy
      class RedisStrategy < BaseStrategy
        def initialize(collection = nil, options = {})
          super
          @redis = options[:redis] || TypeBalancer::Rails.configuration.redis_client
          @default_ttl = options[:ttl] || TypeBalancer::Rails.configuration.redis_ttl
        end

        def store(key, value, ttl = nil)
          validate_key!(key)
          validate_value!(value)
          validate_redis!
          normalized_ttl = normalize_ttl(ttl)

          redis_key = cache_key(key)
          json_value = value.to_json

          if normalized_ttl
            @redis.setex(redis_key, normalized_ttl, json_value)
          else
            @redis.set(redis_key, json_value)
          end

          deep_symbolize_keys(value)
        end

        def fetch(key)
          validate_key!(key)
          validate_redis!
          redis_key = cache_key(key)

          return unless (json_value = @redis.get(redis_key))

          deep_symbolize_keys(JSON.parse(json_value))
        end

        def delete(key)
          validate_key!(key)
          validate_redis!
          redis_key = cache_key(key)
          @redis.del(redis_key)
        end

        def clear
          validate_redis!
          pattern = cache_key('*')
          keys = @redis.keys(pattern)
          @redis.del(*keys) if keys.any?
        end

        def clear_for_scope(scope)
          validate_redis!
          pattern = cache_pattern(scope)
          keys = @redis.keys(pattern)
          @redis.del(*keys) if keys.any?
        end

        def fetch_for_scope(scope)
          validate_redis!
          pattern = cache_pattern(scope)
          keys = @redis.keys(pattern)
          return {} if keys.empty?

          keys.each_with_object({}) do |key, hash|
            if (value = @redis.get(key))
              hash[key] = deep_symbolize_keys(JSON.parse(value))
            end
          end
        end

        def execute(key, value = nil, ttl = nil)
          return fetch(key) if value.nil?

          store(key, value, ttl)
        end

        private

        def validate_redis!
          return if @redis && TypeBalancer::Rails.configuration.redis_enabled?

          raise ArgumentError, 'Redis client not configured'
        end

        def cache_key(key)
          "type_balancer:#{@collection.object_id}:#{key}"
        end

        def cache_pattern(scope = @collection)
          "type_balancer:#{scope.object_id}:*"
        end

        def deep_symbolize_keys(value)
          case value
          when Hash
            value.each_with_object({}) do |(k, v), result|
              result[k.to_sym] = deep_symbolize_keys(v)
            end
          when Array
            value.map { |v| deep_symbolize_keys(v) }
          else
            value
          end
        end
      end
    end
  end
end
