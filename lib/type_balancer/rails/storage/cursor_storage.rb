# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Storage
      # Cursor-based storage implementation using memory
      class CursorStorage < BaseStorage
        def initialize(options = {})
          super
          @store = {}
          @ttl_store = {}
          @mutex = Mutex.new
        end

        def store(key, value, ttl = nil)
          validate_key!(key)
          validate_value!(value)
          validate_ttl!(ttl) if ttl

          @mutex.synchronize do
            @store[key.to_s] = value

            if ttl
              expiry_time = Time.now.to_i + ttl
              @ttl_store[key.to_s] = expiry_time
            end

            cleanup_expired_keys
          end

          value
        end

        def fetch(key)
          validate_key!(key)

          @mutex.synchronize do
            cleanup_expired_keys
            @store[key.to_s]
          end
        end

        def delete(key)
          validate_key!(key)

          @mutex.synchronize do
            @store.delete(key.to_s)
            @ttl_store.delete(key.to_s)
          end
        end

        def clear
          @mutex.synchronize do
            @store.clear
            @ttl_store.clear
          end
        end

        private

        def cleanup_expired_keys
          current_time = Time.now.to_i

          expired_keys = @ttl_store.select { |_, expiry| expiry <= current_time }.keys
          expired_keys.each do |key|
            @store.delete(key)
            @ttl_store.delete(key)
          end
        end
      end
    end
  end
end
