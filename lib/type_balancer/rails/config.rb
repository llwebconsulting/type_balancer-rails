# frozen_string_literal: true

require_relative 'storage/base_storage'
require_relative 'config/configuration'
require_relative 'config/strategy_manager'
require_relative 'config/storage_adapter'

module TypeBalancer
  module Rails
    # Configuration module that ties together all configuration components
    module Config
      class << self
        def load!
          require_components
          register_defaults
        end

        private

        def require_components
          # Storage strategies will be required here once implemented
          # require_relative 'storage/redis_storage'
          # require_relative 'storage/cursor_storage'
        end

        def register_defaults
          # Default strategies will be registered here once implemented
          # StrategyManager.register(:redis, Storage::RedisStorage)
          # StrategyManager.register(:cursor, Storage::CursorStorage)
        end
      end
    end
  end
end
