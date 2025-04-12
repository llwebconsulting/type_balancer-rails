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
        class << self
          def register(name, strategy)
            registry[name] = strategy
          end

          def resolve(name)
            registry.fetch(name) { raise KeyError, "Strategy not found: #{name}" }
          end

          def reset!
            @registry = nil
          end

          private

          def registry
            @registry ||= {}
          end
        end
      end

      class StorageAdapter
        class << self
          def configure_redis(client = nil, &)
            if block_given?
              yield(redis_client)
            else
              @redis_client = client
            end
          end

          def configure_cache(store = nil, &)
            if block_given?
              yield(cache_store)
            else
              @cache_store = store
            end
          end

          attr_reader :redis_client, :cache_store

          def redis_enabled?
            !redis_client.nil?
          end

          def reset!
            @redis_client = nil
            @cache_store = nil
          end
        end
      end
    end
  end
end
