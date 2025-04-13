# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Cursor-based storage strategy
      class CursorStrategy < BaseStrategy
        def initialize(collection, storage_adapter, options = {})
          super
        end

        def execute
          # Implementation for cursor-based execution
          collection
        end

        def store(key, value, ttl = nil)
          validate_key!(key)
          validate_value!(value)
          key = key_for(key)

          if cache_enabled?
            ::Rails.cache.write(key, value, expires_in: normalize_ttl(ttl))
          else
            value
          end
        end

        def fetch(key)
          validate_key!(key)
          key = key_for(key)

          return unless cache_enabled?

          ::Rails.cache.read(key)
        end

        def delete(key)
          validate_key!(key)
          key = key_for(key)

          if cache_enabled?
            ::Rails.cache.delete(key)
          else
            true
          end
        end

        def clear
          ::Rails.cache.clear if cache_enabled?
        end

        def clear_for_scope(scope)
          validate_scope!(scope)
          key_pattern = key_for("#{scope.klass.model_name.plural}*")
          if cache_enabled?
            ::Rails.cache.delete_matched(key_pattern)
          else
            true
          end
        end

        def fetch_for_scope(scope)
          validate_scope!(scope)
          return unless cache_enabled?

          ::Rails.cache.read(key_for(scope.klass.model_name.plural))
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
