# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Strategies::MemoryStrategy do
  let(:collection) do
    instance_double('ActiveRecord::Relation').tap do |double|
      allow(double).to receive(:object_id).and_return(123)
    end
  end

  let(:strategy) { described_class.new(collection) }
  let(:key) { 'test_key' }
  let(:value) { { data: 'test_value' } }
  let(:ttl) { 3600 }

  describe '#initialize' do
    it 'initializes with empty store' do
      expect(strategy.instance_variable_get(:@store)).to eq({})
    end

    it 'accepts optional collection' do
      expect(strategy.instance_variable_get(:@collection)).to eq(collection)
    end

    it 'accepts options hash' do
      options = { ttl: 3600 }
      instance = described_class.new(collection, options)
      expect(instance.instance_variable_get(:@options)).to eq(options)
    end

    it 'can initialize without collection' do
      instance = described_class.new
      expect(instance.instance_variable_get(:@collection)).to be_nil
      expect(instance.instance_variable_get(:@store)).to eq({})
    end
  end

  describe '#store' do
    context 'with valid parameters' do
      it 'stores value with key' do
        strategy.store(key, value)
        expect(strategy.instance_variable_get(:@store)[cache_key(key)]).to eq(value)
      end

      it 'stores value with scope-specific key' do
        scope = double('Scope', object_id: 456)
        strategy.store(key, value, nil, scope: scope)
        expect(strategy.instance_variable_get(:@store)[cache_key(key, scope)]).to eq(value)
      end

      it 'returns stored value' do
        result = strategy.store(key, value)
        expect(result).to eq(value)
      end
    end

    context 'with invalid parameters' do
      it 'validates key presence' do
        expect { strategy.store(nil, value) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end

      it 'validates value presence' do
        expect { strategy.store(key, nil) }.to raise_error(ArgumentError, 'Value cannot be nil')
      end
    end
  end

  describe '#fetch' do
    before do
      strategy.store(key, value)
    end

    context 'when key exists' do
      it 'returns stored value' do
        expect(strategy.fetch(key)).to eq(value)
      end

      it 'returns value for scope-specific key' do
        scope = double('Scope', object_id: 456)
        strategy.store(key, value, nil, scope: scope)
        expect(strategy.fetch(key, scope: scope)).to eq(value)
      end
    end

    context 'when key does not exist' do
      it 'returns nil' do
        expect(strategy.fetch('nonexistent')).to be_nil
      end

      it 'returns nil for nonexistent scope' do
        scope = double('Scope', object_id: 789)
        expect(strategy.fetch(key, scope: scope)).to be_nil
      end
    end

    it 'validates key presence' do
      expect { strategy.fetch(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
    end
  end

  describe '#delete' do
    before do
      strategy.store(key, value)
    end

    it 'removes stored value' do
      strategy.delete(key)
      expect(strategy.fetch(key)).to be_nil
    end

    it 'removes scope-specific value' do
      scope = double('Scope', object_id: 456)
      strategy.store(key, value, nil, scope: scope)
      strategy.delete(key, scope: scope)
      expect(strategy.fetch(key, scope: scope)).to be_nil
    end

    it 'validates key presence' do
      expect { strategy.delete(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
    end
  end

  describe '#clear' do
    before do
      strategy.store('key1', 'value1')
      strategy.store('key2', 'value2')
    end

    it 'removes all stored values' do
      strategy.clear
      expect(strategy.instance_variable_get(:@store)).to be_empty
    end
  end

  describe '#clear_for_scope' do
    let(:scope1) { double('Scope1', object_id: 456) }
    let(:scope2) { double('Scope2', object_id: 789) }

    before do
      strategy.store('key1', 'value1', nil, scope: scope1)
      strategy.store('key2', 'value2', nil, scope: scope1)
      strategy.store('key3', 'value3', nil, scope: scope2)
    end

    it 'clears only values for specified scope' do
      strategy.clear_for_scope(scope1)
      
      expect(strategy.fetch('key1', scope: scope1)).to be_nil
      expect(strategy.fetch('key2', scope: scope1)).to be_nil
      expect(strategy.fetch('key3', scope: scope2)).to eq('value3')
    end
  end

  describe '#fetch_for_scope' do
    let(:scope1) { double('Scope1', object_id: 456) }
    let(:scope2) { double('Scope2', object_id: 789) }

    before do
      strategy.store('key1', 'value1', nil, scope: scope1)
      strategy.store('key2', 'value2', nil, scope: scope1)
      strategy.store('key3', 'value3', nil, scope: scope2)
    end

    it 'returns all values for specified scope' do
      result = strategy.fetch_for_scope(scope1)
      
      expect(result).to include(
        "type_balancer:456:key1" => 'value1',
        "type_balancer:456:key2" => 'value2'
      )
      expect(result).not_to include("type_balancer:789:key3" => 'value3')
    end

    it 'returns empty hash for scope with no values' do
      scope3 = double('Scope3', object_id: 999)
      expect(strategy.fetch_for_scope(scope3)).to be_empty
    end
  end

  describe '#execute' do
    context 'when value is provided' do
      it 'stores the value' do
        strategy.execute(key, value, ttl)
        expect(strategy.fetch(key)).to eq(value)
      end
    end

    context 'when value is not provided' do
      before do
        strategy.store(key, value)
      end

      it 'fetches the value' do
        expect(strategy.execute(key)).to eq(value)
      end
    end
  end

  private

  def cache_key(key, scope = collection)
    scope_id = scope&.object_id || 'nil'
    "type_balancer:#{scope_id}:#{key}"
  end
end 