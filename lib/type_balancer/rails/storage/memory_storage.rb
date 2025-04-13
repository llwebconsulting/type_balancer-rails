# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Storage
      # Memory-based implementation of the storage strategy.
      # Uses a simple hash to store data in memory.
      class MemoryStorage < BaseStorage
        def initialize
          @store = {}
          super(nil) # No client needed for memory storage
        end

        def store(key, value, ttl = nil)
          validate_key!(key)
          validate_value!(value)

          @store[key] = value.to_json
        end

        def fetch(key)
          validate_key!(key)

          return nil unless @store.key?(key)

          JSON.parse(@store[key])
        end

        def delete(key)
          validate_key!(key)

          @store.delete(key)
        end

        def clear(pattern)
          validate_key!(pattern)

          regex = pattern_to_regex(pattern)
          @store.delete_if { |key, _| key.match?(regex) }
        end

        private

        def pattern_to_regex(pattern)
          # Convert Redis-style pattern to regex
          # * becomes .*
          # ? becomes .
          # Escape other special regex characters
          pattern = Regexp.escape(pattern)
                          .gsub('\*', '.*')
                          .gsub('\?', '.')
          Regexp.new("^#{pattern}$")
        end
      end
    end
  end
end
