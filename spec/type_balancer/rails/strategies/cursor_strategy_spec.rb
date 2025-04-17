# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Strategies::CursorStrategy do
  let(:storage_adapter) { instance_double(TypeBalancer::Rails::Config::ConfigStorageAdapter) }
  let(:model_class) { mock_model_class('TestModel') }
  let(:scope) { mock_active_record_relation(model_class) }
  let(:collection) { double('Collection', object_id: 123) }
  let(:options) { { ttl: 3600 } }
  let(:strategy) { described_class.new(collection, storage_adapter, options) }
  let(:key) { 'test_key' }
  let(:value) { { data: 'test_value' } }
  let(:ttl) { 3600 }
  let(:rails_cache) { double('Rails.cache') }

  before do
    stub_const('Rails', Module.new)
    allow(Rails).to receive(:cache).and_return(rails_cache)
    allow(storage_adapter).to receive_messages(cache_enabled?: cache_enabled, redis_enabled?: false)
    allow(TypeBalancer::Rails).to receive(:configuration).and_return(double('configuration', cache_ttl: 7200,
                                                                                             redis_ttl: 7200))
  end

  describe '#initialize' do
    let(:cache_enabled) { true }

    it 'inherits from BaseStrategy' do
      expect(strategy).to be_a(TypeBalancer::Rails::Strategies::BaseStrategy)
    end
  end

  describe '#execute' do
    let(:cache_enabled) { true }

    it 'returns the collection' do
      expect(strategy.execute).to eq(collection)
    end
  end

  describe '#store' do
    context 'when cache is enabled' do
      let(:cache_enabled) { true }

      before do
        allow(rails_cache).to receive(:write).with("type_balancer:123:#{key}", value, expires_in: ttl).and_return(true)
      end

      it 'stores the value in cache' do
        strategy.store(key, value, ttl)
      end

      it 'returns true when storage is successful' do
        expect(strategy.store(key, value, ttl)).to be true
      end

      it 'validates the key' do
        expect { strategy.store(nil, value, ttl) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end

      it 'validates the value' do
        expect { strategy.store(key, nil, ttl) }.to raise_error(ArgumentError, 'Value cannot be nil')
      end
    end

    context 'when cache is disabled' do
      let(:cache_enabled) { false }

      it 'returns the value without storing' do
        expect(rails_cache).not_to receive(:write)
        expect(strategy.store(key, value, ttl)).to eq(value)
      end
    end
  end

  describe '#fetch' do
    context 'when cache is enabled' do
      let(:cache_enabled) { true }

      before do
        allow(rails_cache).to receive(:read).with("type_balancer:123:#{key}").and_return(value)
      end

      it 'reads from cache' do
        strategy.fetch(key)
      end

      it 'returns nil when key not found' do
        allow(rails_cache).to receive(:read).with("type_balancer:123:#{key}").and_return(nil)
        expect(strategy.fetch(key)).to be_nil
      end

      it 'validates the key' do
        expect { strategy.fetch(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end

    context 'when cache is disabled' do
      let(:cache_enabled) { false }

      it 'returns nil without fetching' do
        expect(rails_cache).not_to receive(:read)
        expect(strategy.fetch(key)).to be_nil
      end
    end
  end

  describe '#delete' do
    context 'when cache is enabled' do
      let(:cache_enabled) { true }

      before do
        allow(rails_cache).to receive(:delete).with("type_balancer:123:#{key}").and_return(true)
      end

      it 'deletes from cache' do
        strategy.delete(key)
      end

      it 'validates the key' do
        expect { strategy.delete(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end

    context 'when cache is disabled' do
      let(:cache_enabled) { false }

      it 'returns true without deleting' do
        expect(rails_cache).not_to receive(:delete)
        expect(strategy.delete(key)).to be true
      end
    end
  end

  describe '#clear' do
    context 'when cache is enabled' do
      let(:cache_enabled) { true }

      before do
        allow(rails_cache).to receive(:clear).and_return(true)
      end

      it 'clears the cache' do
        strategy.clear
      end
    end

    context 'when cache is disabled' do
      let(:cache_enabled) { false }

      it 'returns nil without clearing' do
        expect(rails_cache).not_to receive(:clear)
        expect(strategy.clear).to be_nil
      end
    end
  end

  describe '#clear_for_scope' do
    context 'when cache is enabled' do
      let(:cache_enabled) { true }
      let(:model_name) { instance_double(ActiveModel::Name, plural: 'test_models') }
      let(:expected_pattern) { 'type_balancer:123:test_models*' }

      before do
        allow(scope).to receive_messages(
          klass: model_class,
          is_a?: ->(klass) { klass == ActiveRecord::Relation }
        )
        allow(rails_cache).to receive(:delete_matched).with(expected_pattern).and_return(true)
      end

      it 'clears the cache for scope' do
        strategy.clear_for_scope(scope)
      end

      it 'validates the scope is not nil' do
        expect { strategy.clear_for_scope(nil) }.to raise_error(ArgumentError, 'Scope cannot be nil')
      end

      it 'validates the scope is an ActiveRecord::Relation' do
        invalid_scope = double('InvalidScope')
        allow(invalid_scope).to receive(:is_a?).with(ActiveRecord::Relation).and_return(false)
        expect { strategy.clear_for_scope(invalid_scope) }
          .to raise_error(ArgumentError, 'Scope must be an ActiveRecord::Relation')
      end
    end

    context 'when cache is disabled' do
      let(:cache_enabled) { false }

      it 'returns true without clearing' do
        expect(rails_cache).not_to receive(:delete_matched)
        expect(strategy.clear_for_scope(scope)).to be true
      end
    end
  end

  describe '#fetch_for_scope' do
    context 'when cache is enabled' do
      let(:cache_enabled) { true }

      it 'fetches the key for the scope' do
        expect(rails_cache).to receive(:read).with('type_balancer:123:test_models').and_return(value)
        expect(strategy.fetch_for_scope(scope)).to eq(value)
      end

      it 'validates the scope is not nil' do
        expect { strategy.fetch_for_scope(nil) }.to raise_error(ArgumentError, 'Scope cannot be nil')
      end

      it 'validates the scope is an ActiveRecord::Relation' do
        invalid_scope = double('InvalidScope')
        allow(invalid_scope).to receive(:is_a?).with(ActiveRecord::Relation).and_return(false)
        expect { strategy.fetch_for_scope(invalid_scope) }
          .to raise_error(ArgumentError, 'Scope must be an ActiveRecord::Relation')
      end
    end

    context 'when cache is disabled' do
      let(:cache_enabled) { false }

      it 'returns nil without fetching' do
        expect(rails_cache).not_to receive(:read)
        expect(strategy.fetch_for_scope(scope)).to be_nil
      end
    end
  end
end
