# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      # Base class for all storage strategies
      class BaseStrategy
        attr_reader :collection, :options

        def initialize(collection = nil, options = {})
          @collection = collection
          @options = options
          @cache_enabled = TypeBalancer::Rails.configuration.cache_enabled
          @cache_ttl = TypeBalancer::Rails.configuration.cache_ttl
        end

        def execute
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

        private

        def cache_key(key)
          "type_balancer:#{collection.object_id}:#{key}"
        end

        def cache_enabled?
          @cache_enabled
        end

        attr_reader :cache_ttl

        def normalize_ttl(ttl)
          ttl || cache_ttl
        end

        def validate_key!(key)
          raise ArgumentError, 'Key cannot be nil' if key.nil?
          raise ArgumentError, 'Key must be a string or symbol' unless key.is_a?(String) || key.is_a?(Symbol)
        end

        def validate_value!(value)
          raise ArgumentError, 'Value cannot be nil' if value.nil?
        end
      end
    end
  end
end
