# frozen_string_literal: true

module TypeBalancer
  module Rails
    # A facade that buries all configuration complexity
    # Once tested, this class should never need to change
    module ConfigurationFacade
      extend self

      def configuration
        @configuration ||= Config::BaseConfiguration.new
      end

      def configure
        yield(configuration)
        self
      end

      def reset!
        configuration.reset!
        self
      end

      def redis(&)
        if block_given?
          yield(configuration)
        else
          configuration.redis_settings
        end
      end

      def cache(&)
        if block_given?
          yield(configuration)
        else
          configuration.cache_settings
        end
      end

      def storage(&)
        if block_given?
          yield(configuration)
        else
          configuration.storage_settings
        end
      end

      def pagination(&)
        if block_given?
          yield(configuration)
        else
          configuration.pagination_settings
        end
      end

      def validate!
        validate_storage_strategy!
        validate_redis_settings! if redis_enabled?
        validate_cache_settings! if cache_enabled?
        validate_pagination_settings!
        self
      end

      def storage_adapter
        configuration.storage_strategy
      end

      delegate :redis_client, to: :configuration

      delegate :redis_ttl, to: :configuration

      delegate :cache_ttl, to: :configuration

      delegate :cache_enabled?, to: :configuration

      delegate :redis_enabled?, to: :configuration

      delegate :max_per_page, to: :configuration

      delegate :cursor_buffer_multiplier, to: :configuration

      private

      def validate_storage_strategy!
        raise ArgumentError, 'Storage strategy required' unless storage_adapter
      end

      def validate_redis_settings!
        validate_redis_client!
        raise ArgumentError, 'Redis TTL must be positive' unless redis_ttl&.positive?
      end

      def validate_cache_settings!
        validate_cache_store!
        raise ArgumentError, 'Cache TTL must be positive' unless cache_ttl&.positive?
      end

      def validate_pagination_settings!
        raise ArgumentError, 'Max per page must be positive' unless max_per_page&.positive?
        raise ArgumentError, 'Cursor buffer multiplier must be greater than 1' unless cursor_buffer_multiplier&.> 1
      end

      def validate_redis_client!
        client = redis_client
        raise ArgumentError, 'Redis client required when Redis is enabled' unless client

        required_methods = [:get, :set, :del, :scan]
        required_methods.each do |method|
          raise ArgumentError, "Redis client must respond to #{method}" unless client.respond_to?(method)
        end
      end

      def validate_cache_store!
        store = configuration.cache_store
        raise ArgumentError, 'Cache store must be set' unless store

        required_methods = [:read, :write, :delete]
        required_methods.each do |method|
          raise ArgumentError, "Cache store must respond to #{method}" unless store.respond_to?(method)
        end
      end
    end
  end
end
