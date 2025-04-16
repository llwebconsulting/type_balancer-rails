# frozen_string_literal: true

module TypeBalancer
  module Rails
    # A facade that buries all configuration complexity
    # Once tested, this class should never need to change
    class ConfigurationFacade
      class << self
        def redis(&)
          configuration.redis(&)
        end

        def cache(&)
          configuration.cache(&)
        end

        def storage(&)
          configuration.storage_strategy_registry.tap do |registry|
            yield(registry) if block_given?
          end
        end

        def pagination(&)
          configuration.pagination(&)
        end

        delegate :reset!, to: :configuration

        def configuration
          @configuration ||= TypeBalancer::Rails::Config::BaseConfiguration.new
        end

        def validate!
          validate_redis! if configuration.redis_settings[:enabled]
          validate_cache! if configuration.cache_settings[:enabled]
        end

        private

        def validate_redis!
          client = configuration.redis_settings[:client]
          unless client
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Redis client is not configured'
          end

          unless client.respond_to?(:get)
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Redis client must respond to :get'
          end
          unless client.respond_to?(:set)
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Redis client must respond to :set'
          end
          unless client.respond_to?(:del)
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Redis client must respond to :del'
          end
          return if client.respond_to?(:scan)

          raise TypeBalancer::Rails::Errors::ConfigurationError,
                'Redis client must respond to :scan'
        end

        def validate_cache!
          store = ::Rails.cache
          unless store
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Cache store is not configured'
          end

          unless store.respond_to?(:read)
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Cache store must respond to :read'
          end
          unless store.respond_to?(:write)
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Cache store must respond to :write'
          end
          return if store.respond_to?(:delete)

          raise TypeBalancer::Rails::Errors::ConfigurationError,
                'Cache store must respond to :delete'
        end
      end

      def initialize
        @config = TypeBalancer::Rails::Config::BaseConfiguration.new
      end

      def configure
        yield(@config) if block_given?
        self
      end

      def redis
        @config.redis_settings
      end

      def cache
        @config.cache_settings
      end

      def storage
        @config.storage_settings
      end

      def pagination
        @config.pagination_settings
      end

      def reset!
        @config.reset!
        self
      end

      def redis_client
        ensure_configured!
        @config.redis_settings[:client]
      end

      def redis_ttl
        ensure_configured!
        @config.redis_settings[:ttl]
      end

      def redis_enabled?
        ensure_configured!
        @config.redis_settings[:enabled]
      end

      def cache_enabled?
        ensure_configured!
        @config.cache_settings[:enabled]
      end

      def cache_ttl
        ensure_configured!
        @config.cache_settings[:ttl]
      end

      def cache_store
        ensure_configured!
        @config.cache_settings[:store]
      end

      def storage_strategy
        ensure_configured!
        @config.storage_settings[:strategy]
      end

      def max_per_page
        ensure_configured!
        @config.pagination_settings[:max_per_page]
      end

      def cursor_buffer_multiplier
        ensure_configured!
        @config.pagination_settings[:cursor_buffer_multiplier]
      end

      def pagination_settings
        {
          max_per_page: @config.pagination_settings[:max_per_page]
        }
      end

      private

      def ensure_configured!
        return if @config

        reset!
      end

      def validate_configuration!(config)
        validate_redis!(config) if config.redis_settings[:enabled]
        validate_cache!(config) if config.cache_settings[:enabled]
        validate_storage!(config)
        validate_pagination!(config)
      end

      def validate_redis!(config)
        settings = config.redis_settings
        raise ArgumentError, 'Redis client required when Redis is enabled' unless settings[:client]
        raise ArgumentError, 'Redis TTL must be positive' unless settings[:ttl].to_i.positive?
      end

      def validate_cache!(config)
        settings = config.cache_settings
        raise ArgumentError, 'Cache TTL must be positive' unless settings[:ttl].to_i.positive?
      end

      def validate_storage!(config)
        settings = config.storage_settings
        raise ArgumentError, 'Storage strategy required' unless settings[:strategy]
      end

      def validate_pagination!(config)
        settings = config.pagination_settings
        raise ArgumentError, 'Max per page must be positive' unless settings[:max_per_page].to_i.positive?

        return if settings[:cursor_buffer_multiplier].to_f > 1.0

        raise ArgumentError,
              'Cursor buffer multiplier must be greater than 1'
      end

      def validate_pagination_settings!(settings)
        return if settings[:max_per_page].to_i.positive?

        raise ArgumentError, 'max_per_page must be greater than 0'
      end
    end
  end
end
