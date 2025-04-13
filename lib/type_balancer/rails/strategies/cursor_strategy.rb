# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Cursor-based storage strategy
      class CursorStrategy < BaseStrategy
        def initialize(collection = nil, options = {})
          super
          @buffer_multiplier = TypeBalancer::Rails.configuration.cursor_buffer_multiplier
        end

        def execute
          # Implementation for cursor-based execution
          collection
        end

        def store(key, value, ttl = nil)
          validate_key!(key)
          validate_value!(value)
          key = cache_key(key)

          if cache_enabled?
            ::Rails.cache.write(key, value, expires_in: normalize_ttl(ttl))
          else
            value
          end
        end

        def fetch(key)
          validate_key!(key)
          key = cache_key(key)

          return unless cache_enabled?

          ::Rails.cache.read(key)
        end

        def delete(key)
          validate_key!(key)
          key = cache_key(key)

          ::Rails.cache.delete(key) if cache_enabled?
        end

        def clear
          ::Rails.cache.clear if cache_enabled?
        end

        def clear_for_scope(scope)
          validate_scope!(scope)
          key_pattern = cache_key("#{scope.model_name.plural}*")
          ::Rails.cache.delete_matched(key_pattern) if cache_enabled?
        end

        def fetch_for_scope(scope)
          validate_scope!(scope)
          key = cache_key(scope.model_name.plural)
          fetch(key)
        end

        private

        def validate_scope!(scope)
          raise ArgumentError, 'Scope cannot be nil' if scope.nil?
          raise ArgumentError, 'Scope must be an ActiveRecord::Relation' unless scope.is_a?(ActiveRecord::Relation)
        end
      end
    end
  end
end
