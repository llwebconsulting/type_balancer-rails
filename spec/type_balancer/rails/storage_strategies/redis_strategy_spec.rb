# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::StorageStrategies::RedisStrategy do
  let(:redis_client) { instance_double('Redis') }
  let(:configuration) { instance_double('TypeBalancer::Rails::Configuration', redis_client: redis_client) }
  let(:options) { {} }

  before do
    allow(TypeBalancer::Rails).to receive(:configuration).and_return(configuration)
  end

  subject(:strategy) { described_class.new(options) }

  describe '#initialize' do
    context 'when redis client is provided in options' do
      let(:custom_redis) { instance_double('Redis') }
      let(:options) { { redis: custom_redis } }

      it 'uses the provided redis client' do
        expect(strategy.send(:redis)).to eq(custom_redis)
      end
    end

    context 'when redis client is not configured' do
      let(:configuration) { instance_double('TypeBalancer::Rails::Configuration', redis_client: nil) }

      it 'raises an error' do
        expect { strategy }.to raise_error(ArgumentError, 'Redis client not configured')
      end
    end

    context 'with custom TTL' do
      let(:options) { { ttl: 2.hours } }

      it 'uses the provided TTL' do
        expect(strategy.instance_variable_get(:@default_ttl)).to eq(2.hours)
      end
    end
  end

  describe '#store' do
    let(:key) { 'test_key' }
    let(:value) { { test: 'value' } }
    let(:storage_key) { "type_balancer:rails:#{key}" }
    let(:serialized_value) { Marshal.dump(value) }

    before do
      allow(redis_client).to receive(:set)
      allow(redis_client).to receive(:setex)
    end

    it 'serializes and stores the value' do
      strategy.store(key, value)
      expect(redis_client).to have_received(:set).with(storage_key, serialized_value)
    end

    context 'with TTL' do
      let(:ttl) { 3600 }

      it 'stores with expiration' do
        strategy.store(key, value, ttl: ttl)
        expect(redis_client).to have_received(:setex).with(storage_key, ttl, serialized_value)
      end
    end

    context 'with default TTL from initialization' do
      let(:options) { { ttl: 7200 } }

      it 'uses default TTL when none provided' do
        strategy.store(key, value)
        expect(redis_client).to have_received(:setex).with(storage_key, 7200, serialized_value)
      end

      it 'allows override of default TTL' do
        strategy.store(key, value, ttl: 3600)
        expect(redis_client).to have_received(:setex).with(storage_key, 3600, serialized_value)
      end
    end
  end

  describe '#fetch' do
    let(:key) { 'test_key' }
    let(:value) { { test: 'value' } }
    let(:serialized_value) { Marshal.dump(value) }
    let(:storage_key) { "type_balancer:rails:#{key}" }

    before do
      allow(redis_client).to receive(:get).with(storage_key).and_return(serialized_value)
    end

    it 'retrieves and deserializes the value' do
      expect(strategy.fetch(key)).to eq(value)
    end

    context 'when key does not exist' do
      before do
        allow(redis_client).to receive(:get).with(storage_key).and_return(nil)
      end

      it 'returns nil' do
        expect(strategy.fetch(key)).to be_nil
      end
    end

    context 'with invalid data' do
      before do
        allow(redis_client).to receive(:get).with(storage_key).and_return('invalid')
      end

      it 'returns nil and logs error' do
        expect(Rails.logger).to receive(:error).with(/Error deserializing Redis value/)
        expect(strategy.fetch(key)).to be_nil
      end
    end
  end

  describe '#delete' do
    let(:key) { 'test_key' }
    let(:storage_key) { "type_balancer:rails:#{key}" }

    before do
      allow(redis_client).to receive(:del)
    end

    it 'deletes the key' do
      strategy.delete(key)
      expect(redis_client).to have_received(:del).with(storage_key)
    end
  end

  describe '#clear' do
    let(:pattern) { 'type_balancer:rails:*' }
    let(:keys) { ['type_balancer:rails:key1', 'type_balancer:rails:key2'] }

    before do
      allow(redis_client).to receive(:keys).with(pattern).and_return(keys)
      allow(redis_client).to receive(:del)
    end

    it 'deletes all keys with prefix' do
      strategy.clear
      expect(redis_client).to have_received(:del).with(*keys)
    end

    context 'when no keys exist' do
      let(:keys) { [] }

      it 'does not call del' do
        strategy.clear
        expect(redis_client).not_to have_received(:del)
      end
    end
  end
end 