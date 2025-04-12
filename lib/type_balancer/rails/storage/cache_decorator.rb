# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Storage
      # Decorator that adds caching capabilities to storage strategies
      class CacheDecorator
        def initialize(storage)
          @storage = storage
          @cache_store = ::Rails.cache
        end

        def store(key, value, ttl = nil)
          storage.store(key, value, ttl)
          cache_store.write(cache_key(key), value, expires_in: ttl) if cache_enabled?
          value
        end

        def fetch(key)
          if cache_enabled?
            cache_store.fetch(cache_key(key)) do
              storage.fetch(key)
            end
          else
            storage.fetch(key)
          end
        end

        def delete(key)
          storage.delete(key)
          cache_store.delete(cache_key(key)) if cache_enabled?
        end

        def clear
          storage.clear
          cache_store.clear if cache_enabled?
        end

        private

        attr_reader :storage, :cache_store

        def cache_enabled?
          TypeBalancer::Rails.configuration.cache_enabled
        end

        def cache_key(key)
          "type_balancer/#{storage.class.name.demodulize.underscore}/#{key}"
        end
      end
    end
  end
end
