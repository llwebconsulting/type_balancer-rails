# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Strategies::BaseStrategy do
  let(:collection) { instance_double('ActiveRecord::Relation', object_id: 123) }
  let(:options) { { ttl: 3600 } }
  let(:storage_adapter) do
    instance_double('TypeBalancer::Rails::Config::StorageAdapter',
                   cache_enabled: true,
                   cache_ttl: 1.hour)
  end

  subject(:strategy) { described_class.new(collection, options) }

  before do
    stub_const('TypeBalancer::Rails::Config::StorageAdapter', storage_adapter)
  end

  describe '#initialize' do
    it 'sets collection and options' do
      expect(strategy.collection).to eq collection
      expect(strategy.options).to eq options
    end

    it 'sets cache configuration from storage adapter' do
      expect(strategy.send(:cache_enabled?)).to be true
      expect(strategy.send(:cache_ttl)).to eq 1.hour
    end
  end

  describe 'interface methods' do
    %i[execute store fetch delete clear].each do |method|
      it "raises NotImplementedError for ##{method}" do
        args = case method
               when :store then ['key', 'value']
               when :fetch, :delete then ['key']
               else []
               end

        expect { strategy.public_send(method, *args) }
          .to raise_error(NotImplementedError, "#{described_class} must implement ##{method}")
      end
    end
  end

  describe '#cache_key' do
    it 'generates key with collection object_id' do
      expect(strategy.send(:cache_key, 'test'))
        .to eq "type_balancer:123:test"
    end
  end

  describe '#cache_enabled?' do
    context 'when cache is enabled in adapter' do
      it 'returns true' do
        expect(strategy.send(:cache_enabled?)).to be true
      end
    end

    context 'when cache is disabled in adapter' do
      let(:storage_adapter) do
        instance_double('TypeBalancer::Rails::Config::StorageAdapter',
                       cache_enabled: false,
                       cache_ttl: 1.hour)
      end

      it 'returns false' do
        expect(strategy.send(:cache_enabled?)).to be false
      end
    end
  end

  describe '#normalize_ttl' do
    context 'when ttl is provided' do
      it 'returns provided ttl' do
        expect(strategy.send(:normalize_ttl, 7200)).to eq 7200
      end
    end

    context 'when ttl is nil' do
      it 'returns cache_ttl' do
        expect(strategy.send(:normalize_ttl, nil)).to eq 1.hour
      end
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
      expect { strategy.send(:validate_key!, nil) }
        .to raise_error(ArgumentError, 'Key cannot be nil')
    end

    it 'raises error for invalid key types' do
      expect { strategy.send(:validate_key!, 123) }
        .to raise_error(ArgumentError, 'Key must be a string or symbol')
    end
  end

  describe '#validate_value!' do
    it 'accepts non-nil values' do
      expect { strategy.send(:validate_value!, 'test') }.not_to raise_error
      expect { strategy.send(:validate_value!, 123) }.not_to raise_error
      expect { strategy.send(:validate_value!, {}) }.not_to raise_error
    end

    it 'raises error for nil values' do
      expect { strategy.send(:validate_value!, nil) }
        .to raise_error(ArgumentError, 'Value cannot be nil')
    end
  end
end 