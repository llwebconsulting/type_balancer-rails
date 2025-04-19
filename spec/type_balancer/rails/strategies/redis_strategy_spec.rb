# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Strategies::RedisStrategy do
  subject(:strategy) { described_class.new(collection, storage_adapter, options) }

  let(:collection) { instance_double(Object, object_id: 123) }
  let(:storage_adapter) { instance_double(TypeBalancer::Rails::Config::ConfigStorageAdapter) }
  let(:redis_client) { instance_double(Redis) }
  let(:options) { { ttl: 3600 } }

  before do
    allow(storage_adapter).to receive_messages(
      store: true,
      fetch: nil,
      delete: true,
      clear: true,
      clear_for_scope: true,
      fetch_for_scope: {},
      redis_client: redis_client
    )

    allow(redis_client).to receive_messages(
      get: nil,
      setex: true,
      del: true,
      keys: [],
      ping: 'PONG'
    )
  end

  describe '#initialize' do
    context 'with invalid storage adapter' do
      it 'raises error when storage adapter is a hash' do
        expect { described_class.new(collection, {}) }.to raise_error(
          ArgumentError,
          'RedisStrategy requires a ConfigStorageAdapter instance, not a Hash'
        )
      end
    end
  end

  describe '#store' do
    let(:key) { 'test_key' }
    let(:value) { { foo: 'bar' } }

    it 'stores value through storage adapter' do
      expect(storage_adapter).to receive(:store).with("type_balancer:123:#{key}", value, options[:ttl])
      strategy.store(key, value)
    end

    context 'with invalid key' do
      it 'raises error for nil key' do
        expect { strategy.store(nil, value) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end

      it 'raises error for non-string/symbol key' do
        expect { strategy.store(123, value) }.to raise_error(ArgumentError, 'Key must be a string or symbol')
      end
    end

    context 'with invalid value' do
      it 'raises error for nil value' do
        expect { strategy.store(key, nil) }.to raise_error(ArgumentError, 'Value cannot be nil')
      end

      it 'raises error for non-JSON-serializable value' do
        non_serializable = Object.new
        expect do
          strategy.store(key, non_serializable)
        end.to raise_error(ArgumentError, 'Value must be JSON serializable')
      end
    end
  end

  describe '#fetch' do
    let(:key) { 'test_key' }
    let(:value) { { foo: 'bar' } }

    it 'fetches value through storage adapter' do
      expect(storage_adapter).to receive(:fetch).with("type_balancer:123:#{key}")
      strategy.fetch(key)
    end

    context 'with invalid key' do
      it 'raises error for nil key' do
        expect { strategy.fetch(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end
  end

  describe '#delete' do
    let(:key) { 'test_key' }

    it 'deletes key through storage adapter' do
      expect(storage_adapter).to receive(:delete).with("type_balancer:123:#{key}")
      strategy.delete(key)
    end

    context 'with invalid key' do
      it 'raises error for nil key' do
        expect { strategy.delete(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end
  end

  describe '#clear' do
    it 'delegates to storage adapter' do
      expect(storage_adapter).to receive(:clear)
      strategy.clear
    end
  end

  describe '#clear_for_scope' do
    let(:scope) { double('scope', object_id: 456) }

    it 'delegates to storage adapter' do
      expect(storage_adapter).to receive(:clear_for_scope).with(scope)
      strategy.clear_for_scope(scope)
    end
  end

  describe '#fetch_for_scope' do
    let(:scope) { double('scope', object_id: 456) }

    it 'delegates to storage adapter' do
      expect(storage_adapter).to receive(:fetch_for_scope).with(scope)
      strategy.fetch_for_scope(scope)
    end
  end

  describe '#execute' do
    let(:key) { 'test_key' }
    let(:value) { { foo: 'bar' } }

    context 'with value' do
      it 'stores value' do
        expect(storage_adapter).to receive(:store).with("type_balancer:123:#{key}", value, options[:ttl])
        strategy.execute(key, value)
      end
    end

    context 'without value' do
      it 'fetches value' do
        expect(storage_adapter).to receive(:fetch).with("type_balancer:123:#{key}")
        strategy.execute(key)
      end
    end
  end

  describe '#deep_symbolize_keys' do
    it 'symbolizes hash keys recursively' do
      input = { 'a' => { 'b' => { 'c' => 'd' } } }
      expected = { a: { b: { c: 'd' } } }
      expect(strategy.send(:deep_symbolize_keys, input)).to eq(expected)
    end

    it 'handles arrays' do
      input = [{ 'a' => 'b' }, { 'c' => 'd' }]
      expected = [{ a: 'b' }, { c: 'd' }]
      expect(strategy.send(:deep_symbolize_keys, input)).to eq(expected)
    end

    it 'returns non-hash/array values as is' do
      expect(strategy.send(:deep_symbolize_keys, 'string')).to eq('string')
      expect(strategy.send(:deep_symbolize_keys, 123)).to eq(123)
      expect(strategy.send(:deep_symbolize_keys, true)).to be(true)
    end
  end
end
