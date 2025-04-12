require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Core do
  describe TypeBalancer::Rails::Core::Configuration do
    subject(:configuration) { described_class.new }

    describe '#initialize' do
      it 'sets default values' do
        expect(configuration.strategy_manager).to be_nil
        expect(configuration.storage_adapter).to be_nil
        expect(configuration.redis_client).to be_nil
        expect(configuration.cache_ttl).to eq(3600)
      end
    end

    describe '#reset!' do
      before do
        configuration.strategy_manager = double('StrategyManager')
        configuration.storage_adapter = double('StorageAdapter')
        configuration.redis_client = double('RedisClient')
        configuration.cache_ttl = 7200
      end

      it 'resets all attributes to defaults' do
        configuration.reset!

        expect(configuration.strategy_manager).to be_nil
        expect(configuration.storage_adapter).to be_nil
        expect(configuration.redis_client).to be_nil
        expect(configuration.cache_ttl).to eq(3600)
      end
    end

    describe '#configure_redis' do
      let(:redis_client) { double('RedisClient') }

      before do
        configuration.redis_client = redis_client
      end

      it 'yields redis client if block given' do
        expect { |b| configuration.configure_redis(&b) }.to yield_with_args(redis_client)
      end

      it 'returns self for chaining' do
        expect(configuration.configure_redis).to eq(configuration)
      end
    end

    describe '#configure_cache' do
      let(:rails_cache) { double('RailsCache') }

      before do
        stub_const('Rails', double(cache: rails_cache))
      end

      it 'yields Rails.cache if block given' do
        expect { |b| configuration.configure_cache(&b) }.to yield_with_args(rails_cache)
      end

      it 'returns self for chaining' do
        expect(configuration.configure_cache).to eq(configuration)
      end
    end
  end

  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(described_class.configuration).to be_a(TypeBalancer::Rails::Core::Configuration)
    end

    it 'returns the same instance on subsequent calls' do
      first_call = described_class.configuration
      second_call = described_class.configuration
      expect(first_call).to be(second_call)
    end
  end

  describe '.configure' do
    it 'yields configuration if block given' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.configuration)
    end

    it 'returns self for chaining' do
      expect(described_class.configure).to eq(described_class)
    end
  end

  describe '.reset!' do
    before do
      described_class.configuration.cache_ttl = 7200
    end

    it 'resets configuration to defaults' do
      described_class.reset!
      expect(described_class.configuration.cache_ttl).to eq(3600)
    end

    it 'returns self for chaining' do
      expect(described_class.reset!).to eq(described_class)
    end
  end
end 