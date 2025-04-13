# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Base class for all storage strategies
      class BaseStrategy
        attr_reader :collection, :options, :storage_adapter

        def initialize(collection, storage_adapter, options = {})
          @collection = collection
          @storage_adapter = storage_adapter
          @options = options
        end

        def execute(key, value = nil)
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

        delegate :redis_enabled?, to: :@storage_adapter

        def redis_ttl
          @options[:ttl] || TypeBalancer::Rails.configuration.redis_ttl
        end

        def cache_ttl
          @options[:ttl] || TypeBalancer::Rails.configuration.cache_ttl
        end

        def key_for(key)
          raise ArgumentError, 'key cannot be nil' if key.nil?

          "type_balancer:#{@collection.object_id}:#{key}"
        end

        def scope_key_for(key, scope)
          raise ArgumentError, 'key cannot be nil' if key.nil?
          raise ArgumentError, 'scope cannot be nil' if scope.nil?

          "type_balancer:#{@collection.object_id}:#{scope}:#{key}"
        end

        def serialize(value)
          raise ArgumentError, 'value cannot be nil' if value.nil?

          value.to_json
        end

        def deserialize(value)
          raise ArgumentError, 'value cannot be nil' if value.nil?

          JSON.parse(value)
        end

        protected

        def cache_enabled?
          @storage_adapter.cache_enabled?
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
      end
    end
  end
end
