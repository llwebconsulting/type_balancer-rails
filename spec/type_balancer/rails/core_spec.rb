# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Core do
  def setup_test_doubles
    redis_client = double('Redis', ping: 'PONG')
    cache_store = double('ActiveSupport::Cache::Store', read: nil)
    
    redis_strategy = double('RedisStrategy', store: true, fetch: true, configure_redis: true)
    memory_strategy = double('MemoryStrategy', store: true, fetch: true)
    
    strategy_manager = double('TypeBalancer::Rails::Config::StrategyManager', 
      validate!: true,
      registered_strategies?: true,
      registered_strategies: [:redis, :memory],
      strategies: { redis: redis_strategy, memory: memory_strategy }
    )
    
    storage_adapter = double('TypeBalancer::Rails::Config::StorageAdapter', 
      validate!: true,
      configure_redis: nil,
      configure_cache: nil,
      redis_client: redis_client,
      cache_store: cache_store,
      redis_enabled?: true,
      cache_enabled?: true
    )

    allow(::Rails).to receive(:cache).and_return(cache_store)
    allow(TypeBalancer::Rails::Config::StrategyManager).to receive(:new).and_return(strategy_manager)
    allow(TypeBalancer::Rails::Config::StorageAdapter).to receive(:new).with(strategy_manager).and_return(storage_adapter)
    allow(strategy_manager).to receive(:[]).with(:redis).and_return(redis_strategy)
    allow(strategy_manager).to receive(:[]).with(:memory).and_return(memory_strategy)
    allow(storage_adapter).to receive(:configure_redis).with(redis_client).and_return(storage_adapter)
    allow(storage_adapter).to receive(:configure_cache).with(cache_store).and_return(storage_adapter)

    [redis_client, cache_store, strategy_manager, storage_adapter]
  end

  describe '.configure' do
    after { described_class.reset! }

    it 'yields configuration object when block given' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(TypeBalancer::Rails::Core::Configuration)
    end

    it 'returns self when no block given' do
      expect(described_class.configure).to eq(described_class)
    end

    it 'allows chaining configuration calls' do
      result = described_class.configure do |config|
        config.cache_ttl = 7200
      end
      expect(result).to eq(described_class)
    end
  end

  describe '.configuration' do
    after { described_class.reset! }

    it 'returns a Configuration instance' do
      expect(described_class.configuration).to be_a(TypeBalancer::Rails::Core::Configuration)
    end

    it 'memoizes the configuration instance' do
      config = described_class.configuration
      expect(described_class.configuration).to be(config)
    end

    it 'initializes with default values' do
      config = described_class.configuration
      expect(config.redis_enabled).to be true
      expect(config.cache_enabled).to be true
      expect(config.cache_ttl).to eq(3600)
      expect(config.redis_ttl).to eq(3600)
      expect(config.redis_client).to be_nil
      expect(config.strategy_manager).to be_a(TypeBalancer::Rails::Config::StrategyManager)
      expect(config.storage_adapter).to be_a(TypeBalancer::Rails::Config::StorageAdapter)
    end

    context 'after reset' do
      it 'returns a new configuration instance' do
        original_config = described_class.configuration
        described_class.reset!
        expect(described_class.configuration).not_to be(original_config)
      end
    end
  end

  describe '.reset!' do
    after { described_class.reset! }

    before do
      described_class.configure do |config|
        config.cache_ttl = 7200
        config.redis_ttl = 7200
      end
    end

    it 'resets configuration to default values' do
      described_class.reset!
      config = described_class.configuration
      
      expect(config.cache_ttl).to eq(3600)
      expect(config.redis_ttl).to eq(3600)
      expect(config.redis_client).to be_nil
    end

    it 'returns self' do
      expect(described_class.reset!).to eq(described_class)
    end
  end

  describe 'integration with components' do
    after { described_class.reset! }

    let(:redis_client) { double('Redis', ping: 'PONG') }
    let(:cache_store) { double('ActiveSupport::Cache::Store', read: nil) }
    let(:redis_strategy) { double('RedisStrategy', store: true, fetch: true, configure_redis: true) }
    let(:memory_strategy) { double('MemoryStrategy', store: true, fetch: true) }
    let(:strategies) { { redis: redis_strategy, memory: memory_strategy } }
    let(:strategy_manager) do
      instance_double('TypeBalancer::Rails::Config::StrategyManager').tap do |manager|
        allow(manager).to receive(:validate!) do
          raise TypeBalancer::Rails::Errors::ConfigurationError, 'No strategies registered' if strategies.empty?
          strategies.each_value { |strategy| strategy.respond_to?(:store) && strategy.respond_to?(:fetch) }
          true
        end
        allow(manager).to receive(:strategies).and_return(strategies)
        allow(manager).to receive(:register).with(:redis, any_args).and_return(manager)
        allow(manager).to receive(:register).with(:memory, any_args).and_return(manager)
        allow(manager).to receive(:[]).with(:redis).and_return(redis_strategy)
        allow(manager).to receive(:[]).with(:memory).and_return(memory_strategy)
      end
    end
    let(:storage_adapter) do
      double('TypeBalancer::Rails::Config::StorageAdapter', 
        validate!: true,
        configure_redis: nil,
        configure_cache: nil,
        redis_client: redis_client,
        cache_store: cache_store,
        redis_enabled?: true,
        cache_enabled?: true
      )
    end

    before do
      allow(::Rails).to receive(:cache).and_return(cache_store)
      
      # Mock the StrategyManager class
      strategy_manager_class = class_double('TypeBalancer::Rails::Config::StrategyManager').as_stubbed_const
      allow(strategy_manager_class).to receive(:new) do
        strategies[:redis] = redis_strategy
        strategies[:memory] = memory_strategy
        strategy_manager
      end
      
      # Mock the StorageAdapter class
      storage_adapter_class = class_double('TypeBalancer::Rails::Config::StorageAdapter').as_stubbed_const
      allow(storage_adapter_class).to receive(:new).with(strategy_manager).and_return(storage_adapter)
      
      # Mock the storage adapter's configuration methods
      allow(storage_adapter).to receive(:configure_redis).with(redis_client).and_return(storage_adapter)
      allow(storage_adapter).to receive(:configure_cache).with(cache_store).and_return(storage_adapter)
      
      # Reset the configuration to ensure a clean state
      described_class.reset!
    end

    it 'configures redis and cache together' do
      described_class.configure do |config|
        config.redis_client = redis_client
        config.cache_ttl = 7200
        config.redis_ttl = 7200
      end

      config = described_class.configuration
      expect(config.redis_client).to eq(redis_client)
      expect(config.cache_ttl).to eq(7200)
      expect(config.redis_ttl).to eq(7200)
    end

    it 'validates configuration after setup' do
      described_class.configure do |config|
        config.redis_client = redis_client
        config.cache_ttl = -1
      end

      expect {
        described_class.configuration.validate!
      }.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Cache TTL must be positive')
    end

    it 'maintains configuration state between calls' do
      described_class.configure { |c| c.redis_client = redis_client }
      described_class.configure { |c| c.cache_ttl = 7200 }

      config = described_class.configuration
      expect(config.redis_client).to eq(redis_client)
      expect(config.cache_ttl).to eq(7200)
    end

    context 'when configuring storage adapter' do
      it 'initializes and configures storage components' do
        expect(storage_adapter).to receive(:configure_redis).with(redis_client).once.and_return(storage_adapter)
        expect(storage_adapter).to receive(:configure_cache).with(cache_store).once.and_return(storage_adapter)

        described_class.configure do |config|
          config.redis_client = redis_client
        end

        config = described_class.configuration
        config.configure_redis
        config.configure_cache
      end

      it 'raises error when configuring redis without client' do
        described_class.configure { |c| c.redis_client = nil }
        expect {
          described_class.configuration.configure_redis
        }.to raise_error(TypeBalancer::Rails::Errors::RedisError, 'Redis client is not configured')
      end

      it 'raises error when configuring cache without store' do
        allow(::Rails).to receive(:cache).and_return(nil)
        expect {
          described_class.configuration.configure_cache
        }.to raise_error(TypeBalancer::Rails::Errors::CacheError, 'Cache store is not configured')
      end

      it 'yields redis client when block given to configure_redis' do
        described_class.configure { |c| c.redis_client = redis_client }
        expect { |b| described_class.configuration.configure_redis(&b) }.to yield_with_args(redis_client)
      end

      it 'yields cache store when block given to configure_cache' do
        expect { |b| described_class.configuration.configure_cache(&b) }.to yield_with_args(cache_store)
      end
    end

    context 'when validating TTL values' do
      it 'raises error for non-numeric cache_ttl' do
        described_class.configure { |c| c.cache_ttl = 'invalid' }
        expect {
          described_class.configuration.validate!
        }.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Cache TTL must be an integer')
      end

      it 'raises error for zero cache_ttl' do
        described_class.configure { |c| c.cache_ttl = 0 }
        expect {
          described_class.configuration.validate!
        }.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Cache TTL must be positive')
      end

      it 'raises error for non-numeric redis_ttl' do
        described_class.configure { |c| c.redis_ttl = 'invalid' }
        expect {
          described_class.configuration.validate!
        }.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Redis TTL must be an integer')
      end

      it 'raises error for zero redis_ttl' do
        described_class.configure { |c| c.redis_ttl = 0 }
        expect {
          described_class.configuration.validate!
        }.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Redis TTL must be positive')
      end

      it 'raises first error when both TTLs are invalid' do
        described_class.configure do |c| 
          c.cache_ttl = 'invalid'
          c.redis_ttl = 0
        end
        expect {
          described_class.configuration.validate!
        }.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Cache TTL must be an integer')
      end
    end

    context 'when validating component configurations' do
      it 'propagates errors from strategy manager validation' do
        allow(strategy_manager).to receive(:validate!).and_raise(
          TypeBalancer::Rails::Errors::ConfigurationError, 'Strategy validation failed'
        )

        described_class.configure { |c| c.redis_client = redis_client }
        expect {
          described_class.configuration.validate!
        }.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Invalid strategy: Strategy validation failed')
      end

      it 'propagates errors from storage adapter validation' do
        allow(storage_adapter).to receive(:validate!).and_raise(
          TypeBalancer::Rails::Errors::ConfigurationError, 'Storage validation failed'
        )

        described_class.configure { |c| c.redis_client = redis_client }
        expect {
          described_class.configuration.validate!
        }.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Invalid storage: Storage validation failed')
      end
    end
  end

  describe TypeBalancer::Rails::Core::StorageStrategyRegistry do
    let(:registry) { described_class.new }
    let(:strategy_class) { Class.new }

    describe '#register' do
      it 'registers a new strategy class' do
        registry.register(:test, strategy_class)
        expect(registry[:test]).to eq(strategy_class)
      end

      it 'overwrites existing strategy when registering with same name' do
        another_strategy = Class.new
        registry.register(:test, strategy_class)
        registry.register(:test, another_strategy)
        expect(registry[:test]).to eq(another_strategy)
      end
    end

    describe '#[]' do
      it 'returns nil for unregistered strategy' do
        expect(registry[:nonexistent]).to be_nil
      end

      it 'returns registered strategy class' do
        registry.register(:test, strategy_class)
        expect(registry[:test]).to eq(strategy_class)
      end
    end

    describe '#clear' do
      it 'removes all registered strategies' do
        registry.register(:test1, Class.new)
        registry.register(:test2, Class.new)
        registry.clear
        expect(registry[:test1]).to be_nil
        expect(registry[:test2]).to be_nil
      end
    end
  end
end 