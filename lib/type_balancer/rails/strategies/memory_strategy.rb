# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Memory-based storage strategy using Rails cache
      class MemoryStrategy < BaseStrategy
        def initialize(collection = nil, options = {})
          super
          @store = {}
        end

        def store(key, value, ttl = nil, scope: nil)
          validate_key!(key)
          validate_value!(value)
          key = scope ? cache_key(key, scope) : cache_key(key)
          @store[key] = value
          value
        end

        def fetch(key, scope: nil)
          validate_key!(key)
          key = scope ? cache_key(key, scope) : cache_key(key)
          @store[key]
        end

        def delete(key, scope: nil)
          validate_key!(key)
          key = scope ? cache_key(key, scope) : cache_key(key)
          @store.delete(key)
        end

        delegate :clear, to: :@store

        def clear_for_scope(scope)
          pattern = cache_pattern(scope)
          @store.keys.each do |key|
            @store.delete(key) if key.start_with?(pattern)
          end
        end

        def fetch_for_scope(scope)
          pattern = cache_pattern(scope)
          @store.select { |key, _| key.start_with?(pattern) }
        end

        def execute(key, value = nil, ttl = nil)
          return fetch(key) if value.nil?

          store(key, value, ttl)
        end

        private

        def cache_pattern(scope = @collection)
          "type_balancer:#{scope.object_id}:"
        end

        def cache_key(key, scope = @collection)
          "type_balancer:#{scope.object_id}:#{key}"
        end
      end
    end
  end
end
