# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Strategies::MemoryStrategy do
  let(:collection) { double('Collection', object_id: 123) }
  let(:options) { { ttl: 3600 } }
  let(:storage_adapter) { instance_double('TypeBalancer::Rails::Config::StorageAdapter') }
  
  subject(:strategy) { described_class.new(collection, options) }

  before do
    allow(TypeBalancer::Rails::Config::StorageAdapter).to receive(:new).and_return(storage_adapter)
  end

  describe '#store' do
    let(:key) { 'test_key' }
    let(:value) { { data: 'test' } }
    let(:memory_key) { "type_balancer:123:#{key}" }

    it 'stores value in memory' do
      strategy.store(key, value)
      expect(strategy.fetch(key)).to eq(value)
    end

    context 'with scope' do
      let(:scope) { double('Scope', object_id: 456) }
      let(:scoped_key) { "type_balancer:456:#{key}" }

      it 'stores value with scoped key' do
        strategy.store(key, value, nil, scope: scope)
        expect(strategy.fetch(key, scope: scope)).to eq(value)
      end
    end

    context 'with invalid key' do
      it 'raises ArgumentError' do
        expect { strategy.store(nil, value) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end

    context 'with invalid value' do
      it 'raises ArgumentError' do
        expect { strategy.store(key, nil) }.to raise_error(ArgumentError, 'Value cannot be nil')
      end
    end
  end

  describe '#fetch' do
    let(:key) { 'test_key' }
    let(:value) { { data: 'test' } }

    context 'when key exists' do
      before { strategy.store(key, value) }

      it 'returns stored value' do
        expect(strategy.fetch(key)).to eq(value)
      end
    end

    context 'when key does not exist' do
      it 'returns nil' do
        expect(strategy.fetch(key)).to be_nil
      end
    end

    context 'with scope' do
      let(:scope) { double('Scope', object_id: 456) }

      before { strategy.store(key, value, nil, scope: scope) }

      it 'returns value for scoped key' do
        expect(strategy.fetch(key, scope: scope)).to eq(value)
      end
    end

    context 'with invalid key' do
      it 'raises ArgumentError' do
        expect { strategy.fetch(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end
  end

  describe '#delete' do
    let(:key) { 'test_key' }
    let(:value) { { data: 'test' } }

    before { strategy.store(key, value) }

    it 'removes the key' do
      strategy.delete(key)
      expect(strategy.fetch(key)).to be_nil
    end

    context 'with scope' do
      let(:scope) { double('Scope', object_id: 456) }

      before { strategy.store(key, value, nil, scope: scope) }

      it 'removes scoped key' do
        strategy.delete(key, scope: scope)
        expect(strategy.fetch(key, scope: scope)).to be_nil
      end
    end

    context 'with invalid key' do
      it 'raises ArgumentError' do
        expect { strategy.delete(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end
  end

  describe '#clear' do
    let(:keys) { %w[key1 key2] }
    let(:values) { { data1: 'test1', data2: 'test2' } }

    before do
      keys.each_with_index do |key, index|
        strategy.store(key, values[:"data#{index + 1}"])
      end
    end

    it 'removes all stored values' do
      strategy.clear
      keys.each do |key|
        expect(strategy.fetch(key)).to be_nil
      end
    end
  end

  describe '#clear_for_scope' do
    let(:scope) { double('Scope', object_id: 456) }
    let(:keys) { %w[key1 key2] }
    let(:values) { { data1: 'test1', data2: 'test2' } }

    before do
      # Store some values with scope
      keys.each_with_index do |key, index|
        strategy.store(key, values[:"data#{index + 1}"], nil, scope: scope)
      end

      # Store some values without scope
      keys.each_with_index do |key, index|
        strategy.store(key, values[:"data#{index + 1}"])
      end
    end

    it 'removes only scoped values' do
      strategy.clear_for_scope(scope)

      # Scoped values should be gone
      keys.each do |key|
        expect(strategy.fetch(key, scope: scope)).to be_nil
      end

      # Non-scoped values should remain
      keys.each_with_index do |key, index|
        expect(strategy.fetch(key)).to eq(values[:"data#{index + 1}"])
      end
    end
  end

  describe '#fetch_for_scope' do
    let(:scope) { double('Scope', object_id: 456) }
    let(:keys) { %w[key1 key2] }
    let(:values) { { data1: 'test1', data2: 'test2' } }

    before do
      keys.each_with_index do |key, index|
        strategy.store(key, values[:"data#{index + 1}"], nil, scope: scope)
      end
    end

    it 'returns hash of all values for scope' do
      result = strategy.fetch_for_scope(scope)
      expected = keys.each_with_index.map do |key, index|
        [
          "type_balancer:456:#{key}",
          values[:"data#{index + 1}"]
        ]
      end.to_h

      expect(result).to eq(expected)
    end

    context 'when scope has no values' do
      let(:empty_scope) { double('Scope', object_id: 789) }

      it 'returns empty hash' do
        expect(strategy.fetch_for_scope(empty_scope)).to eq({})
      end
    end
  end

  describe '#execute' do
    context 'with value' do
      it 'calls store' do
        value = { test: 'data' }
        expect(strategy).to receive(:store).with('key', value, nil)
        strategy.execute('key', value)
      end
    end

    context 'without value' do
      it 'calls fetch' do
        expect(strategy).to receive(:fetch).with('key')
        strategy.execute('key')
      end
    end
  end
end 