# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Core do
  before { described_class.reset! if described_class.respond_to?(:reset!) }

  after { described_class.reset! if described_class.respond_to?(:reset!) }

  describe '.configure' do
    let(:redis_client) { double('Redis', ping: 'PONG', set: true) }
    let(:cache_store) { double('ActiveSupport::Cache::Store', read: nil) }

    before do
      allow(Rails).to receive(:cache).and_return(cache_store)
    end

    it 'yields configuration object when block given' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(TypeBalancer::Rails::Config::RuntimeConfiguration)
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
    context 'with default configuration' do
      it 'returns a Configuration instance' do
        expect(described_class.configuration).to be_a(TypeBalancer::Rails::Config::RuntimeConfiguration)
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
        expect(config.storage_adapter).to be_a(TypeBalancer::Rails::Config::ConfigStorageAdapter)
      end
    end
  end

  describe '.reset!' do
    let(:redis_client) { double('Redis', ping: 'PONG') }

    it 'resets configuration to default values' do
      described_class.configure do |config|
        config.cache_ttl = 7200
        config.redis_ttl = 7200
        config.redis_client = redis_client
      end

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
    context 'with test doubles' do
      let(:redis_client) { double('Redis', ping: 'PONG', set: true) }
      let(:cache_store) { double('ActiveSupport::Cache::Store', read: nil) }
      let(:redis_strategy) { double('RedisStrategy', store: true, fetch: true, configure_redis: true) }
      let(:memory_strategy) { double('MemoryStrategy', store: true, fetch: true) }
      let(:strategies_hash) { { redis: redis_strategy, memory: memory_strategy } }
      let(:strategy_manager_instance) do
        instance_double(TypeBalancer::Rails::Config::StrategyManager).tap do |manager|
          allow(manager).to receive_messages(strategies: strategies_hash, validate!: true)
          allow(manager).to receive(:register) do |name, strategy|
            strategies_hash[name] = strategy
            true
          end
          allow(manager).to receive(:[]) { |name| strategies_hash[name] }
        end
      end
      let(:storage_adapter) do
        instance_double(TypeBalancer::Rails::Config::ConfigStorageAdapter).tap do |adapter|
          allow(adapter).to receive_messages(validate!: true, configure_redis: adapter, configure_cache: adapter,
                                             store: true)
        end
      end

      before do
        described_class.reset!
        allow(Rails).to receive(:cache).and_return(cache_store)

        # Set up class doubles
        strategy_manager_class = class_double(TypeBalancer::Rails::Config::StrategyManager).as_stubbed_const
        storage_adapter_class = class_double(TypeBalancer::Rails::Config::ConfigStorageAdapter).as_stubbed_const

        allow(strategy_manager_class).to receive(:new).and_return(strategy_manager_instance)
        allow(storage_adapter_class).to receive(:new).with(strategy_manager_instance).and_return(storage_adapter)

        # Register strategies
        described_class.configuration.strategy_manager.register(:redis, redis_strategy)
        described_class.configuration.strategy_manager.register(:memory, memory_strategy)
      end

      it 'validates configuration after setup' do
        described_class.configure do |config|
          config.redis_client = redis_client
          config.cache_ttl = -1
        end

        expect do
          described_class.configuration.validate!
        end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Cache TTL must be positive')
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
          described_class.configure do |config|
            config.redis_client = redis_client
            config.configure_redis
            config.configure_cache
          end

          config = described_class.configuration
          config.validate!
        end

        it 'propagates errors from storage adapter validation' do
          described_class.configure do |config|
            config.redis_client = redis_client
            config.configure_redis
            config.configure_cache
          end

          # Set up the validation error expectation after configuration
          storage_adapter = described_class.configuration.storage_adapter
          expect(storage_adapter).to receive(:validate!).and_raise(
            TypeBalancer::Rails::Errors::ConfigurationError, 'Storage validation failed'
          )

          expect do
            described_class.configuration.validate!
          end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                             'Invalid storage: Storage validation failed')
        end
      end
    end

    context 'with real objects' do
      before { described_class.reset! }

      it 'creates default objects' do
        config = described_class.configuration
        expect(config.strategy_manager).to be_a(TypeBalancer::Rails::Config::StrategyManager)
        expect(config.storage_adapter).to be_a(TypeBalancer::Rails::Config::ConfigStorageAdapter)
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
