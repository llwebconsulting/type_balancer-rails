# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Base class for all storage strategies
      class BaseStrategy
        attr_reader :collection, :options

        def initialize(collection, options = {})
          @collection = collection
          @options = options
          @storage_adapter = TypeBalancer::Rails::Config::StorageAdapter
        end

        def execute(*)
          raise NotImplementedError, "#{self.class} must implement #execute"
        end

        def store(key, value, ttl = nil)
          raise NotImplementedError, "#{self.class} must implement #store"
        end

        def fetch(key)
          raise NotImplementedError, "#{self.class} must implement #fetch"
        end

        def delete(key)
          raise NotImplementedError, "#{self.class} must implement #delete"
        end

        def clear
          raise NotImplementedError, "#{self.class} must implement #clear"
        end

        def clear_for_scope(scope)
          raise NotImplementedError, "#{self.class} must implement #clear_for_scope"
        end

        def fetch_for_scope(scope)
          raise NotImplementedError, "#{self.class} must implement #fetch_for_scope"
        end

        protected

        def cache_enabled?
          @storage_adapter.cache_enabled
        end

        def cache_ttl
          options[:ttl] || @storage_adapter.cache_ttl
        end

        def cache_key(key)
          "type_balancer:#{collection.object_id}:#{key}"
        end

        def validate_key!(key)
          raise ArgumentError, 'Key cannot be nil' if key.nil?
          raise ArgumentError, 'Key must be a string or symbol' unless key.is_a?(String) || key.is_a?(Symbol)
        end

        def validate_value!(value)
          raise ArgumentError, 'Value cannot be nil' if value.nil?
          raise ArgumentError, 'Value must be JSON serializable' unless value.respond_to?(:to_json)
        end

        def normalize_ttl(ttl = nil)
          ttl || cache_ttl
        end

        def redis_enabled?
          @storage_adapter.redis_enabled
        end
      end
    end
  end
end
