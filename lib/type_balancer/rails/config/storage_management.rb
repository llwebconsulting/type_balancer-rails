module TypeBalancer
  module Rails
    module Config
      module StorageManagement
        # Add storage management methods here
        def setup_storage
          @strategy_manager = TypeBalancer::Rails::Config::StrategyManager.new
          @storage_adapter = TypeBalancer::Rails::Config::ConfigStorageAdapter.new(@strategy_manager)
          register_default_storage_strategies
        end

        def register_default_storage_strategies
          @storage_strategy_registry.register(:memory, TypeBalancer::Rails::Strategies::MemoryStrategy)
          @storage_strategy_registry.register(:redis, TypeBalancer::Rails::Strategies::RedisStrategy)
        end
      end
    end
  end
end
