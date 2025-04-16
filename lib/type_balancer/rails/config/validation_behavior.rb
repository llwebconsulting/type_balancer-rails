# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      module ValidationBehavior
        # Add validation methods here
        def validate!
          strategy_manager.validate!
          storage_adapter.validate!
          validate_redis_ttl! if redis_enabled?
          validate_cache_ttl! if cache_enabled?
          true
        end

        private

        def validate_redis_ttl!
          return unless redis_enabled?

          return if redis_ttl.is_a?(Integer) && redis_ttl.positive?

          raise TypeBalancer::Rails::Errors::ConfigurationError, 'redis_ttl must be a positive integer'
        end

        def validate_cache_ttl!
          return unless cache_enabled?

          return if cache_ttl.is_a?(Integer) && cache_ttl.positive?

          raise TypeBalancer::Rails::Errors::ConfigurationError, 'cache_ttl must be a positive integer'
        end
      end
    end
  end
end
