# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Storage
      # Base class for all storage strategies
      class BaseStorage
        def initialize(options = {})
          @options = options
        end

        # Store a value with an optional TTL
        # @param key [String, Symbol] The key to store the value under
        # @param value [Object] The value to store
        # @param ttl [Integer, nil] Optional TTL in seconds
        # @raise [ArgumentError] If key or value is invalid
        def store(key, value, ttl = nil)
          raise NotImplementedError, "#{self.class} must implement #store"
        end

        # Fetch a value by key
        # @param key [String, Symbol] The key to fetch
        # @return [Object, nil] The stored value or nil if not found
        # @raise [ArgumentError] If key is invalid
        def fetch(key)
          raise NotImplementedError, "#{self.class} must implement #fetch"
        end

        # Delete a value by key
        # @param key [String, Symbol] The key to delete
        # @raise [ArgumentError] If key is invalid
        def delete(key)
          raise NotImplementedError, "#{self.class} must implement #delete"
        end

        # Clear all stored values
        def clear
          raise NotImplementedError, "#{self.class} must implement #clear"
        end

        protected

        attr_reader :options

        def validate_key!(key)
          raise ArgumentError, 'Key cannot be nil' if key.nil?
          raise ArgumentError, 'Key must be a string or symbol' unless key.is_a?(String) || key.is_a?(Symbol)
          raise ArgumentError, 'Key cannot be empty' if key.is_a?(String) && key.strip.empty?
        end

        def validate_value!(value)
          raise ArgumentError, 'Value cannot be nil' if value.nil?
          raise ArgumentError, 'Value must respond to to_json' unless value.respond_to?(:to_json)
        end

        def validate_ttl!(ttl)
          return if ttl.nil?
          raise ArgumentError, 'TTL must be a non-negative integer' unless ttl.is_a?(Integer) && ttl >= 0
        end
      end
    end
  end
end
