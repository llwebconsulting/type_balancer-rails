# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Storage::RedisStorage do
  let(:redis_client) do
    instance_double('Redis').tap do |client|
      allow(client).to receive(:set)
      allow(client).to receive(:setex)
      allow(client).to receive(:get)
      allow(client).to receive(:del)
      allow(client).to receive(:keys)
    end
  end

  let(:options) { { redis: redis_client } }
  let(:storage) { described_class.new(options) }
  let(:key) { 'test_key' }
  let(:value) { { data: 'test_value' } }
  let(:ttl) { 3600 }

  # Create a class that doesn't respond to to_json
  let(:non_serializable_object) do
    Class.new do
      undef_method :to_json if method_defined?(:to_json)
    end.new
  end

  describe '#initialize' do
    context 'with custom redis client' do
      it 'uses the provided client' do
        expect(storage.send(:redis)).to eq(redis_client)
      end
    end

    context 'with default configuration client' do
      let(:config_client) { instance_double('Redis') }
      let(:storage) { described_class.new }

      before do
        allow(TypeBalancer::Rails.configuration).to receive(:redis_client).and_return(config_client)
      end

      it 'uses the configuration client' do
        expect(storage.send(:redis)).to eq(config_client)
      end
    end

    context 'without redis client' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:redis_client).and_return(nil)
      end

      it 'raises an error' do
        expect { described_class.new }.to raise_error(ArgumentError, 'Redis client not configured')
      end
    end
  end

  describe '#store' do
    let(:storage_key) { "type_balancer:rails:#{key}" }
    let(:serialized_value) { Marshal.dump(value) }

    context 'with valid parameters' do
      it 'stores the value' do
        expect(redis_client).to receive(:set).with(storage_key, serialized_value)
        expect(storage.store(key, value)).to eq(value)
      end

      context 'with TTL' do
        it 'stores with expiration' do
          expect(redis_client).to receive(:setex).with(storage_key, ttl, serialized_value)
          expect(storage.store(key, value, ttl)).to eq(value)
        end
      end
    end

    context 'with invalid parameters' do
      it 'validates key presence' do
        expect { storage.store(nil, value) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end

      it 'validates key type' do
        expect { storage.store(123, value) }.to raise_error(ArgumentError, 'Key must be a string or symbol')
      end

      it 'validates empty key' do
        expect { storage.store('', value) }.to raise_error(ArgumentError, 'Key cannot be empty')
      end

      it 'validates value presence' do
        expect { storage.store(key, nil) }.to raise_error(ArgumentError, 'Value cannot be nil')
      end

      it 'validates value serialization' do
        expect { storage.store(key, non_serializable_object) }.to raise_error(ArgumentError, 'Value must respond to to_json')
      end

      it 'validates TTL type' do
        expect { storage.store(key, value, -1) }.to raise_error(ArgumentError, 'TTL must be a non-negative integer')
      end
    end
  end

  describe '#fetch' do
    let(:storage_key) { "type_balancer:rails:#{key}" }

    context 'when key exists' do
      before do
        allow(redis_client).to receive(:get).with(storage_key).and_return(Marshal.dump(value))
      end

      it 'returns the deserialized value' do
        expect(storage.fetch(key)).to eq(value)
      end
    end

    context 'when key does not exist' do
      before do
        allow(redis_client).to receive(:get).with(storage_key).and_return(nil)
      end

      it 'returns nil' do
        expect(storage.fetch(key)).to be_nil
      end
    end

    context 'with invalid deserialization' do
      before do
        allow(redis_client).to receive(:get).with(storage_key).and_return('invalid')
      end

      it 'returns nil' do
        expect(storage.fetch(key)).to be_nil
      end
    end

    context 'with invalid key' do
      it 'validates key presence' do
        expect { storage.fetch(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end
  end

  describe '#delete' do
    let(:storage_key) { "type_balancer:rails:#{key}" }

    it 'deletes the key' do
      expect(redis_client).to receive(:del).with(storage_key)
      storage.delete(key)
    end

    it 'validates key presence' do
      expect { storage.delete(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
    end
  end

  describe '#clear' do
    let(:pattern) { 'type_balancer:rails:*' }
    let(:keys) { ['key1', 'key2'] }

    before do
      allow(redis_client).to receive(:keys).with(pattern).and_return(keys)
    end

    it 'deletes all keys matching the pattern' do
      expect(redis_client).to receive(:del).with(*keys)
      storage.clear
    end

    context 'when no keys exist' do
      let(:keys) { [] }

      it 'does not call del' do
        expect(redis_client).not_to receive(:del)
        storage.clear
      end
    end
  end
end 