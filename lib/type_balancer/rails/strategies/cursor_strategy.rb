# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Cursor-based storage strategy
      class CursorStrategy < BaseStrategy
        def initialize
          super
          @buffer_multiplier = TypeBalancer::Rails.configuration.cursor_buffer_multiplier
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
      end
    end
  end
end
