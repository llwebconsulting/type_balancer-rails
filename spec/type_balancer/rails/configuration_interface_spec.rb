# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails do
  before do
    described_class.reset!
  end

  describe '.configure' do
    it 'yields configuration instance when block given' do
      expect { |b| described_class.configure(&b) }
        .to yield_with_args(TypeBalancer::Rails::Config::Configuration)
    end

    it 'returns self for chaining' do
      expect(described_class.configure).to eq described_class
    end
  end

  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(described_class.configuration)
        .to be_a(TypeBalancer::Rails::Config::Configuration)
    end

    it 'memoizes the configuration instance' do
      config = described_class.configuration
      expect(described_class.configuration).to be config
    end
  end

  describe '.strategy_manager' do
    it 'returns the StrategyManager class' do
      expect(described_class.strategy_manager)
        .to eq TypeBalancer::Rails::Config::StrategyManager
    end
  end

  describe '.storage_adapter' do
    it 'returns the StorageAdapter class' do
      expect(described_class.storage_adapter)
        .to eq TypeBalancer::Rails::Config::StorageAdapter
    end
  end

  describe '.reset!' do
    it 'resets configuration' do
      original_config = described_class.configuration
      described_class.reset!
      expect(described_class.configuration).not_to be original_config
    end

    it 'resets strategy manager' do
      expect(described_class.strategy_manager).to receive(:reset!)
      described_class.reset!
    end

    it 'resets storage adapter' do
      expect(described_class.storage_adapter).to receive(:reset!)
      described_class.reset!
    end
  end

  describe '.register_strategy' do
    let(:strategy) { double('Strategy') }

    it 'delegates to strategy manager' do
      expect(described_class.strategy_manager)
        .to receive(:register).with(:test, strategy)
      
      described_class.register_strategy(:test, strategy)
    end
  end

  describe '.resolve_strategy' do
    let(:strategy) { double('Strategy') }

    it 'delegates to strategy manager' do
      expect(described_class.strategy_manager)
        .to receive(:resolve).with(:test).and_return(strategy)
      
      expect(described_class.resolve_strategy(:test)).to eq strategy
    end
  end

  describe '.configure_redis' do
    let(:client) { double('RedisClient') }

    it 'delegates to storage adapter' do
      expect(described_class.storage_adapter)
        .to receive(:configure_redis).with(client)
      
      described_class.configure_redis(client)
    end
  end

  describe '.configure_cache' do
    let(:store) { double('CacheStore') }

    it 'delegates to storage adapter' do
      expect(described_class.storage_adapter)
        .to receive(:configure_cache).with(store)
      
      described_class.configure_cache(store)
    end
  end

  describe '.redis_enabled?' do
    it 'delegates to storage adapter' do
      expect(described_class.storage_adapter)
        .to receive(:redis_enabled?)
      
      described_class.redis_enabled?
    end
  end
end 