# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Railtie < ::Rails::Railtie
      initializer 'type_balancer.configure_rails_initialization' do
        TypeBalancer::Rails.configure do |config|
          # Register default strategies
          config.register_strategy(:cursor, TypeBalancer::Rails::Strategies::CursorStrategy)
          config.register_strategy(:redis, TypeBalancer::Rails::Strategies::RedisStrategy)

          # Set default strategy
          config.storage_strategy = :cursor

          # Configure cache settings
          config.cache_enabled = true
          config.cache_ttl = 3600 # 1 hour default
        end

        # Include the ActiveRecord extension
        ActiveSupport.on_load(:active_record) do
          include TypeBalancer::Rails::ActiveRecordExtension
        end
      end
    end
  end
end
