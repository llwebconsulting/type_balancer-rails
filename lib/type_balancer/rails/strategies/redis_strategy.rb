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
          unless @redis && TypeBalancer::Rails.configuration.redis_enabled?
            raise ArgumentError,
                  'Redis client not configured'
          end

          @default_ttl = options[:ttl] || TypeBalancer::Rails.configuration.redis_ttl
        end

        def store(key, value, ttl = nil)
          validate_key!(key)
          validate_value!(value)
          key = cache_key(key)
          ttl ||= @default_ttl

          if ttl && ttl > 0
            @redis.setex(key, ttl.to_i, value.to_json)
          else
            @redis.set(key, value.to_json)
          end
        end

        def fetch(key)
          validate_key!(key)
          key = cache_key(key)
          value = @redis.get(key)
          return nil unless value

          begin
            JSON.parse(value, symbolize_names: true)
          rescue JSON::ParserError
            nil
          end
        end

        def delete(key)
          validate_key!(key)
          @redis.del(cache_key(key))
        end

        def clear
          pattern = cache_pattern
          keys = @redis.keys(pattern)
          @redis.del(*keys) if keys.any?
        end

        def clear_for_scope(scope)
          pattern = cache_pattern_for_scope(scope)
          keys = @redis.keys(pattern)
          @redis.del(*keys) if keys.any?
        end

        def fetch_for_scope(scope)
          pattern = cache_pattern_for_scope(scope)
          keys = @redis.keys(pattern)
          return {} if keys.empty?

          keys.each_with_object({}) do |key, result|
            value = @redis.get(key)
            next unless value

            begin
              result[key] = JSON.parse(value, symbolize_names: true)
            rescue JSON::ParserError
              next
            end
          end
        end

        private

        attr_reader :redis

        def cache_pattern
          "type_balancer:#{@collection.object_id}:*"
        end

        def cache_pattern_for_scope(scope)
          "type_balancer:#{scope.object_id}:*"
        end
      end
    end
  end
end
