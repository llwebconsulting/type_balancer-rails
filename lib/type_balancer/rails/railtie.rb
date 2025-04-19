# frozen_string_literal: true

require_relative 'config/runtime_configuration'
require_relative 'active_record_extension'

module TypeBalancer
  module Rails
    class Railtie < ::Rails::Railtie
      config.after_initialize do
        TypeBalancer::Rails.configure do |config|
          # First enable features
          config.enable_cache
          config.enable_redis

          # Then set specific configuration values
          config.cache_ttl = 3600
          config.redis_ttl = 3600
          config.storage_strategy = :redis
        end

        # Include the ActiveRecord extension
        ActiveSupport.on_load(:active_record) do
          include TypeBalancer::Rails::ActiveRecordExtension
        end
      end
    end
  end
end
