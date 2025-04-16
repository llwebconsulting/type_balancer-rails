# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Strategies::BaseStrategy do
  subject(:strategy) { described_class.new(collection, storage_adapter, options) }

  let(:collection) { double('collection') }
  let(:storage_adapter) { double('storage_adapter') }
  let(:options) { { ttl: 3600 } }
  let(:strategy_manager) { double('strategy_manager') }
  let(:configuration) { double('configuration') }

  before do
    allow(TypeBalancer::Rails::Config::ConfigStorageAdapter).to receive(:new).with(strategy_manager).and_return(storage_adapter)
    allow(storage_adapter).to receive_messages(cache_enabled?: true, redis_enabled?: true)
    allow(TypeBalancer::Rails).to receive(:configuration).and_return(configuration)
    allow(configuration).to receive_messages(cache_ttl: 7200, redis_ttl: 7200)
    allow(collection).to receive(:object_id).and_return(6140)
  end

  describe '#initialize' do
    it 'sets collection, storage_adapter and options' do
      expect(strategy.collection).to eq(collection)
      expect(strategy.storage_adapter).to eq(storage_adapter)
      expect(strategy.options).to eq(options)
    end
  end

  describe '#cache_enabled?' do
    context 'when cache is enabled' do
      it 'returns true' do
        expect(strategy.send(:cache_enabled?)).to be true
      end
    end

    context 'when cache is disabled' do
      before { allow(storage_adapter).to receive(:cache_enabled?).and_return(false) }

      it 'returns false' do
        expect(strategy.send(:cache_enabled?)).to be false
      end
    end
  end

  describe '#redis_enabled?' do
    context 'when redis is enabled' do
      it 'returns true' do
        expect(strategy.send(:redis_enabled?)).to be true
      end
    end

    context 'when redis is disabled' do
      before { allow(storage_adapter).to receive(:redis_enabled?).and_return(false) }

      it 'returns false' do
        expect(strategy.send(:redis_enabled?)).to be false
      end
    end
  end

  describe '#cache_ttl' do
    context 'when options ttl is present' do
      it 'returns options ttl' do
        expect(strategy.cache_ttl).to eq(3600)
      end
    end

    context 'when options ttl is not present' do
      let(:options) { {} }

      it 'returns configuration ttl' do
        expect(strategy.cache_ttl).to eq(TypeBalancer::Rails.configuration.cache_ttl)
      end
    end
  end

  describe '#redis_ttl' do
    context 'when options ttl is present' do
      it 'returns options ttl' do
        expect(strategy.redis_ttl).to eq(3600)
      end
    end

    context 'when options ttl is not present' do
      let(:options) { {} }

      it 'returns configuration ttl' do
        expect(strategy.redis_ttl).to eq(TypeBalancer::Rails.configuration.redis_ttl)
      end
    end
  end

  describe '#key_for' do
    it 'returns key with collection id' do
      expect(strategy.key_for('test')).to eq('type_balancer:6140:test')
    end

    it 'raises error when key is nil' do
      expect { strategy.key_for(nil) }.to raise_error(ArgumentError, 'key cannot be nil')
    end
  end

  describe '#scope_key_for' do
    it 'returns key with collection id and scope' do
      expect(strategy.scope_key_for('test', 'scope')).to eq('type_balancer:6140:scope:test')
    end

    it 'raises error when key is nil' do
      expect { strategy.scope_key_for(nil, 'scope') }.to raise_error(ArgumentError, 'key cannot be nil')
    end

    it 'raises error when scope is nil' do
      expect { strategy.scope_key_for('test', nil) }.to raise_error(ArgumentError, 'scope cannot be nil')
    end
  end

  describe '#serialize' do
    it 'serializes value to JSON' do
      expect(strategy.serialize({ test: 'value' })).to eq('{"test":"value"}')
    end

    it 'raises error when value is nil' do
      expect { strategy.serialize(nil) }.to raise_error(ArgumentError, 'value cannot be nil')
    end

    it 'raises error when value is not JSON serializable' do
      value = Class.new do
        undef_method :to_json
      end.new
      expect { strategy.serialize(value) }.to raise_error(NoMethodError)
    end
  end

  describe '#deserialize' do
    it 'deserializes JSON to hash with string keys' do
      expect(strategy.deserialize('{"test":"value"}')).to eq({ 'test' => 'value' })
    end

    it 'raises error when value is nil' do
      expect { strategy.deserialize(nil) }.to raise_error(ArgumentError, 'value cannot be nil')
    end

    it 'raises error when value is not valid JSON' do
      expect { strategy.deserialize('invalid') }.to raise_error(JSON::ParserError)
    end
  end

  describe '#validate_key!' do
    it 'accepts string keys' do
      expect { strategy.send(:validate_key!, 'test') }.not_to raise_error
    end

    it 'accepts symbol keys' do
      expect { strategy.send(:validate_key!, :test) }.not_to raise_error
    end

    it 'raises error for nil keys' do
      expect { strategy.send(:validate_key!, nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
    end

    it 'raises error for invalid key types' do
      expect { strategy.send(:validate_key!, 123) }.to raise_error(ArgumentError, 'Key must be a string or symbol')
    end
  end

  describe '#validate_value!' do
    it 'accepts JSON serializable values' do
      expect { strategy.send(:validate_value!, { test: 'value' }) }.not_to raise_error
    end

    it 'raises error for nil values' do
      expect { strategy.send(:validate_value!, nil) }.to raise_error(ArgumentError, 'Value cannot be nil')
    end

    it 'raises error for non-JSON-serializable values' do
      non_serializable = BasicObject.new
      expect { strategy.send(:validate_value!, non_serializable) }.to raise_error(NoMethodError)
    end
  end

  describe '#normalize_ttl' do
    it 'returns provided ttl when present' do
      expect(strategy.send(:normalize_ttl, 1800)).to eq(1800)
    end

    it 'returns cache_ttl when no ttl provided' do
      expect(strategy.send(:normalize_ttl)).to eq(3600)
    end
  end

  describe 'abstract interface' do
    describe '#store' do
      it 'raises NotImplementedError' do
        key = 'test_key'
        value = { test: 'value' }
        ttl = 3600
        expect { strategy.store(key, value, ttl) }.to raise_error(NotImplementedError)
      end
    end

    describe '#fetch' do
      it 'raises NotImplementedError' do
        key = 'test_key'
        expect { strategy.fetch(key) }.to raise_error(NotImplementedError)
      end
    end

    describe '#delete' do
      it 'raises NotImplementedError' do
        key = 'test_key'
        expect { strategy.delete(key) }.to raise_error(NotImplementedError)
      end
    end

    describe '#clear' do
      it 'raises NotImplementedError' do
        expect { strategy.clear }.to raise_error(NotImplementedError)
      end
    end

    describe '#clear_for_scope' do
      it 'raises NotImplementedError' do
        scope = 'test_scope'
        expect { strategy.clear_for_scope(scope) }.to raise_error(NotImplementedError)
      end
    end

    describe '#fetch_for_scope' do
      it 'raises NotImplementedError' do
        scope = 'test_scope'
        expect { strategy.fetch_for_scope(scope) }.to raise_error(NotImplementedError)
      end
    end

    describe '#execute' do
      it 'raises NotImplementedError' do
        key = 'test_key'
        value = { test: 'value' }
        ttl = 3600
        expect { strategy.execute(key: key, value: value, ttl: ttl) }.to raise_error(NotImplementedError)
      end
    end
  end
end
