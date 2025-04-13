# frozen_string_literal: true

require_relative 'storage/base_storage'

module TypeBalancer
  module Rails
    # Configuration module that ties together all configuration components
    module Config
      class << self
        def configure
          yield TypeBalancer::Rails.configuration if block_given?
          self
        end

        delegate :configuration, to: :'TypeBalancer::Rails'

        delegate :reset!, to: :'TypeBalancer::Rails'

        delegate :load!, to: :'TypeBalancer::Rails'
      end

      class StrategyManager
        attr_reader :strategies

        def initialize
          @strategies = {}
        end

        def register(name, strategy)
          @strategies[name] = strategy
        end

        delegate :[], to: :strategies

        def validate!
          raise TypeBalancer::Rails::Errors::ConfigurationError, 'No strategies registered' if strategies.empty?

          strategies.each_value do |strategy|
            unless strategy.respond_to?(:store) && strategy.respond_to?(:fetch)
              raise TypeBalancer::Rails::Errors::StrategyError,
                    "Invalid strategy: #{strategy}"
            end
          end
          true
        end

        def reset!
          @strategies = {}
        end
      end

      class StorageAdapter
        attr_reader :redis_client, :cache_store

        def initialize(redis_client = nil, cache_store = nil)
          @redis_client = redis_client
          @cache_store = cache_store || ::Rails.cache
        end

        def store(key:, value:, ttl: nil)
          if redis_enabled?
            redis_client.set(key, value.to_json, ex: ttl)
          else
            cache_store.write(key, value, expires_in: ttl)
          end
        end

        def fetch(key)
          if redis_enabled?
            result = redis_client.get(key)
            result ? JSON.parse(result, symbolize_names: true) : nil
          else
            cache_store.read(key)
          end
        end

        def delete(key)
          if redis_enabled?
            redis_client.del(key)
          else
            cache_store.delete(key)
          end
        end

        def clear
          if redis_enabled?
            redis_client.flushdb
          else
            cache_store.clear
          end
        end

        def validate!
          if redis_enabled?
            unless redis_client.respond_to?(:set) && redis_client.respond_to?(:get)
              raise TypeBalancer::Rails::Errors::RedisError,
                    'Redis client is not properly configured'
            end
          else
            unless cache_store.respond_to?(:write) && cache_store.respond_to?(:read)
              raise TypeBalancer::Rails::Errors::CacheError,
                    'Cache store is not properly configured'
            end
          end
          true
        end

        private

        def redis_enabled?
          !redis_client.nil? && redis_client.respond_to?(:set)
        end
      end

      class CacheConfig
        attr_accessor :enabled, :ttl

        def initialize(enabled: true, ttl: 1.hour)
          @enabled = enabled
          @ttl = ttl
        end

        def configure
          yield(::Rails.cache) if block_given?
        end

        def reset!
          @enabled = true
          @ttl = 1.hour
        end
      end

      class RedisConfig
        attr_accessor :client, :enabled

        def initialize(enabled: true)
          @enabled = enabled
          @client = nil
        end

        def configure
          yield(self) if block_given?
        end

        def reset!
          @enabled = true
          @client = nil
        end
      end
    end
  end
end
