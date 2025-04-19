# frozen_string_literal: true

require 'json'

module TypeBalancer
  module Rails
    module Strategies
      # Redis-based storage strategy
      class RedisStrategy < BaseStrategy
        def initialize(collection = nil, storage_adapter = nil, options = {})
          if storage_adapter.is_a?(Hash)
            raise ArgumentError,
                  'RedisStrategy requires a ConfigStorageAdapter instance, not a Hash'
          end

          super
        end

        def store(key, value, ttl = nil)
          validate_key!(key)
          validate_value!(value)
          @storage_adapter.store(key_for(key), value, ttl)
        end

        def fetch(key)
          validate_key!(key)
          @storage_adapter.fetch(key_for(key))
        end

        def delete(key)
          validate_key!(key)
          @storage_adapter.delete(key_for(key))
        end

        delegate :clear, to: :@storage_adapter

        delegate :clear_for_scope, to: :@storage_adapter

        delegate :fetch_for_scope, to: :@storage_adapter

        def execute(key, value = nil, ttl = nil)
          return fetch(key) if value.nil?

          store(key, value, ttl)
        end

        private

        def validate_key!(key)
          raise ArgumentError, 'Key cannot be nil' if key.nil?
          raise ArgumentError, 'Key must be a string or symbol' unless key.is_a?(String) || key.is_a?(Symbol)
        end

        def validate_value!(value)
          raise ArgumentError, 'Value cannot be nil' if value.nil?
          raise ArgumentError, 'Value must be JSON serializable' unless value.respond_to?(:to_json)
        end
      end
    end
  end
end
