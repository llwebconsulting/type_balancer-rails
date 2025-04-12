# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Configuration
      # Configuration for caching
      class CacheConfig
        attr_reader :store, :enabled, :ttl

        def initialize(enabled: true, ttl: 3600)
          @enabled = enabled
          @ttl = ttl
          @store = nil
        end

        def configure(store = nil)
          if store
            ::Rails.cache = store
            @store = store
          end
          yield(::Rails.cache) if block_given?
          self
        end

        def enable!
          @enabled = true
        end

        def disable!
          @enabled = false
        end

        def ttl=(value)
          @ttl = value.to_i
        end

        def reset!
          @enabled = true
          @store = nil
          @ttl = 3600
        end
      end
    end
  end
end
