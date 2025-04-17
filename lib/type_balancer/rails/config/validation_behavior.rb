# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      module ValidationBehavior
        def validate!
          validate_strategy_manager! if defined?(@strategy_manager)
          validate_storage_adapter! if defined?(@storage_adapter)
          validate_redis_ttl! if redis_enabled?
          validate_cache_ttl! if cache_enabled?
          true
        end

        private

        def validate_strategy_manager!
          if @strategy_manager.nil?
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Strategy manager is not configured'
          end

          @strategy_manager.validate!
        rescue StandardError => e
          raise TypeBalancer::Rails::Errors::ConfigurationError, "Strategy manager validation failed: #{e.message}"
        end

        def validate_storage_adapter!
          if @storage_adapter.nil?
            raise TypeBalancer::Rails::Errors::ConfigurationError,
                  'Storage adapter is not configured'
          end

          @storage_adapter.validate!
        rescue StandardError => e
          raise TypeBalancer::Rails::Errors::ConfigurationError, "Storage adapter validation failed: #{e.message}"
        end

        def validate_redis_ttl!
          return unless redis_enabled?
          return if @redis_ttl.is_a?(Integer) && @redis_ttl.positive?

          raise TypeBalancer::Rails::Errors::ConfigurationError,
                'Redis TTL must be a positive integer'
        end

        def validate_cache_ttl!
          return unless cache_enabled?
          return if @cache_ttl.is_a?(Integer) && @cache_ttl.positive?

          raise TypeBalancer::Rails::Errors::ConfigurationError,
                'Cache TTL must be a positive integer'
        end
      end
    end
  end
end
