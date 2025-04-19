require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Config::ConfigStorageAdapter do
  subject(:adapter) { described_class.new(strategy_manager) }

  let(:strategy_manager) { instance_double(TypeBalancer::Rails::Config::StrategyManager) }
  let(:redis_client) { instance_double(Redis) }
  let(:cache_store) { Rails.cache }

  before do
    allow(strategy_manager).to receive(:validate!)
    allow(redis_client).to receive(:ping).and_return('PONG')
    allow(TypeBalancer::Rails.configuration).to receive_messages(
      redis_client: redis_client,
      redis_enabled?: true,
      cache_enabled?: true,
      redis_ttl: 3600,
      cache_ttl: 3600
    )
  end

  describe '#configure_redis' do
    let(:redis_strategy) { instance_double(TypeBalancer::Rails::Strategies::RedisStrategy) }

    before do
      allow(TypeBalancer::Rails::Strategies::RedisStrategy).to receive(:new).and_return(redis_strategy)
    end

    it 'configures redis client and registers strategy' do
      expect(strategy_manager).to receive(:register).with(:redis, redis_strategy)
      adapter.configure_redis(redis_client)
      expect(adapter.redis_client).to eq(redis_client)
    end

    it 'validates redis connection' do
      expect(redis_client).to receive(:ping).and_return('PONG')
      adapter.configure_redis(redis_client)
      adapter.validate!
    end

    context 'when redis client is nil' do
      it 'raises an error' do
        expect { adapter.configure_redis(nil) }.to raise_error(
          TypeBalancer::Rails::Errors::RedisError,
          'Redis client is not configured'
        )
      end
    end

    context 'when redis ping fails' do
      before do
        allow(redis_client).to receive(:ping).and_raise(Redis::CannotConnectError)
      end

      it 'raises an error' do
        expect { adapter.configure_redis(redis_client) }.to raise_error(
          TypeBalancer::Rails::Errors::RedisError,
          'Cannot connect to Redis server'
        )
      end
    end
  end

  describe '#configure_cache' do
    it 'configures cache store' do
      adapter.configure_cache(cache_store)
      expect(adapter.cache_store).to eq(cache_store)
    end

    context 'when cache store is nil' do
      it 'raises an error' do
        expect { adapter.configure_cache(nil) }.to raise_error(
          TypeBalancer::Rails::Errors::CacheError,
          'Cache store is not configured'
        )
      end
    end
  end

  describe '#validate!' do
    before do
      adapter.configure_redis(redis_client)
      adapter.configure_cache(cache_store)
    end

    it 'validates redis and cache configuration' do
      expect(redis_client).to receive(:ping).and_return('PONG')
      expect(strategy_manager).to receive(:validate!)
      expect { adapter.validate! }.not_to raise_error
    end

    context 'when redis is enabled but not configured' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:redis_enabled?).and_return(true)
        allow(adapter).to receive(:redis_client).and_return(nil)
      end

      it 'raises an error' do
        expect { adapter.validate! }.to raise_error(
          TypeBalancer::Rails::Errors::ConfigurationError,
          'Redis is enabled but not configured'
        )
      end
    end

    context 'when cache is enabled but not configured' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled?).and_return(true)
        allow(adapter).to receive(:cache_store).and_return(nil)
      end

      it 'raises an error' do
        expect { adapter.validate! }.to raise_error(
          TypeBalancer::Rails::Errors::ConfigurationError,
          'Cache is enabled but not configured'
        )
      end
    end

    context 'when only redis is enabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive_messages(
          redis_enabled?: true,
          cache_enabled?: false
        )
      end

      it 'validates only redis configuration' do
        expect(redis_client).to receive(:ping).and_return('PONG')
        expect(strategy_manager).to receive(:validate!)
        expect { adapter.validate! }.not_to raise_error
      end

      it 'does not require cache to be configured' do
        allow(adapter).to receive(:cache_store).and_return(nil)
        expect { adapter.validate! }.not_to raise_error
      end
    end

    context 'when only cache is enabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive_messages(
          redis_enabled?: false,
          cache_enabled?: true
        )
      end

      it 'validates only cache configuration' do
        expect(redis_client).not_to receive(:ping)
        expect(strategy_manager).to receive(:validate!)
        expect { adapter.validate! }.not_to raise_error
      end

      it 'does not require redis to be configured' do
        allow(adapter).to receive(:redis_client).and_return(nil)
        expect { adapter.validate! }.not_to raise_error
      end
    end
  end

  describe 'redis operations' do
    before do
      adapter.configure_redis(redis_client)
    end

    describe '#store_in_redis' do
      it 'stores value with TTL' do
        expect(redis_client).to receive(:setex).with('test_key', 3600, '{"value":"test"}')
        adapter.store_in_redis('test_key', { value: 'test' })
      end
    end

    describe '#fetch_from_redis' do
      context 'when key exists' do
        before do
          allow(redis_client).to receive(:get).with('test_key').and_return('{"value":"test"}')
        end

        it 'returns deserialized value' do
          expect(adapter.fetch_from_redis('test_key')).to eq({ 'value' => 'test' })
        end
      end

      context 'when key does not exist' do
        before do
          allow(redis_client).to receive(:get).with('test_key').and_return(nil)
        end

        it 'returns nil' do
          expect(adapter.fetch_from_redis('test_key')).to be_nil
        end
      end
    end

    describe '#delete_from_redis' do
      it 'deletes key' do
        expect(redis_client).to receive(:del).with('test_key')
        adapter.delete_from_redis('test_key')
      end
    end
  end
end
