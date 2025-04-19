# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/config/strategy_manager'
require 'type_balancer/rails/config/storage_adapter'

RSpec.describe TypeBalancer::Rails::Config::ConfigStorageAdapter do
  subject(:adapter) { described_class.new(strategy_manager) }

  let(:strategy_manager) { instance_double(TypeBalancer::Rails::Config::StrategyManager) }
  let(:redis_client) { instance_double(Redis) }
  let(:cache_store) { instance_double(ActiveSupport::Cache::Store) }
  let(:test_key) { 'test_key' }
  let(:test_value) { { name: 'test', value: 123 } }
  let(:test_ttl) { 3600 }
  let(:redis_strategy) { instance_double(TypeBalancer::Rails::Strategies::RedisStrategy) }

  before do
    allow(strategy_manager).to receive(:validate!)
    allow(TypeBalancer::Rails::Strategies::RedisStrategy).to receive(:new).and_return(redis_strategy)
    allow(strategy_manager).to receive(:register)
  end

  describe '#store' do
    context 'when redis is enabled' do
      before do
        allow(redis_client).to receive(:ping).and_return('PONG')
        adapter.configure_redis(redis_client)
      end

      it 'stores value in redis with ttl' do
        expect(redis_client).to receive(:set).with(test_key, test_value.to_json, ex: test_ttl)
        adapter.store(test_key, test_value, test_ttl)
      end

      it 'stores value in redis without ttl' do
        expect(redis_client).to receive(:set).with(test_key, test_value.to_json)
        adapter.store(test_key, test_value)
      end

      it 'registers redis strategy with manager' do
        expect(TypeBalancer::Rails::Strategies::RedisStrategy).to have_received(:new).with(nil, adapter)
        expect(strategy_manager).to have_received(:register).with(:redis, redis_strategy)
      end
    end

    context 'when cache is enabled' do
      before do
        allow(cache_store).to receive(:read).with('test_key').and_return(nil)
        adapter.configure_cache(cache_store)
      end

      it 'stores value in cache with ttl' do
        expect(cache_store).to receive(:write).with(test_key, test_value, expires_in: test_ttl)
        adapter.store(test_key, test_value, test_ttl)
      end

      it 'stores value in cache without ttl' do
        expect(cache_store).to receive(:write).with(test_key, test_value)
        adapter.store(test_key, test_value)
      end
    end
  end

  describe '#fetch' do
    context 'when redis is enabled' do
      before do
        allow(redis_client).to receive(:ping).and_return('PONG')
        adapter.configure_redis(redis_client)
      end

      it 'fetches value from redis' do
        json_value = test_value.to_json
        allow(redis_client).to receive(:get).with(test_key).and_return(json_value)
        result = adapter.fetch(test_key)
        expect(result).to eq JSON.parse(test_value.to_json, symbolize_names: true)
      end

      it 'returns nil when key not found' do
        allow(redis_client).to receive(:get).with(test_key).and_return(nil)
        expect(adapter.fetch(test_key)).to be_nil
      end
    end

    context 'when cache is enabled' do
      before do
        allow(cache_store).to receive(:read).with('test_key').and_return(nil)
        adapter.configure_cache(cache_store)
      end

      it 'fetches value from cache' do
        allow(cache_store).to receive(:read).with(test_key).and_return(test_value)
        result = adapter.fetch(test_key)
        expect(result).to eq test_value
      end

      it 'returns nil when key not found' do
        allow(cache_store).to receive(:read).with(test_key).and_return(nil)
        expect(adapter.fetch(test_key)).to be_nil
      end
    end
  end

  describe '#delete' do
    context 'when redis is enabled' do
      before do
        allow(redis_client).to receive(:ping).and_return('PONG')
        adapter.configure_redis(redis_client)
      end

      it 'deletes value from redis' do
        expect(redis_client).to receive(:del).with(test_key)
        adapter.delete(test_key)
      end
    end

    context 'when cache is enabled' do
      before do
        allow(cache_store).to receive(:read).with('test_key').and_return(nil)
        adapter.configure_cache(cache_store)
      end

      it 'deletes value from cache' do
        expect(cache_store).to receive(:delete).with(test_key)
        adapter.delete(test_key)
      end
    end
  end

  describe '#exists?' do
    context 'when redis is enabled' do
      before do
        allow(redis_client).to receive(:ping).and_return('PONG')
        adapter.configure_redis(redis_client)
      end

      it 'checks existence in redis' do
        allow(redis_client).to receive(:exists?).with(test_key).and_return(true)
        expect(adapter.exists?(test_key)).to be true
      end
    end

    context 'when cache is enabled' do
      before do
        allow(cache_store).to receive(:read).with('test_key').and_return(nil)
        adapter.configure_cache(cache_store)
      end

      it 'checks existence in cache' do
        allow(cache_store).to receive(:exist?).with(test_key).and_return(true)
        expect(adapter.exists?(test_key)).to be true
      end
    end
  end

  describe '#validate!' do
    it 'validates strategy manager' do
      allow(redis_client).to receive(:ping).and_return('PONG')
      adapter.configure_redis(redis_client)
      expect(strategy_manager).to receive(:validate!)
      adapter.validate!
    end

    it 'validates redis when enabled' do
      expect(redis_client).to receive(:ping).and_return('PONG').twice
      adapter.configure_redis(redis_client)
      adapter.validate!
    end

    it 'validates cache when enabled' do
      expect(cache_store).to receive(:read).with('test_key').and_return(nil).twice
      adapter.configure_cache(cache_store)
      adapter.validate!
    end
  end
end
