# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Core::StorageStrategyRegistry do
  let(:registry) { described_class.new }
  let(:strategy) { instance_double(TypeBalancer::Rails::Strategies::BaseStrategy) }

  describe '#initialize' do
    it 'creates an empty registry' do
      expect(registry.instance_variable_get(:@strategies)).to be_empty
    end
  end

  describe '#register' do
    it 'registers a strategy with a string name' do
      registry.register('test', strategy)
      expect(registry[:test]).to eq(strategy)
    end

    it 'registers a strategy with a symbol name' do
      registry.register(:test, strategy)
      expect(registry[:test]).to eq(strategy)
    end

    it 'overwrites existing strategy with same name' do
      new_strategy = instance_double(TypeBalancer::Rails::Strategies::BaseStrategy)

      registry.register(:test, strategy)
      registry.register(:test, new_strategy)

      expect(registry[:test]).to eq(new_strategy)
    end
  end

  describe '#[]' do
    before { registry.register(:test, strategy) }

    it 'retrieves registered strategy by symbol' do
      expect(registry[:test]).to eq(strategy)
    end

    it 'returns nil for unregistered strategy' do
      expect(registry[:unknown]).to be_nil
    end

    it 'converts string keys to symbols' do
      expect(registry['test']).to eq(strategy)
    end
  end

  describe '#clear' do
    before do
      registry.register(:test1, strategy)
      registry.register(:test2, strategy)
    end

    it 'removes all registered strategies' do
      registry.clear
      expect(registry.instance_variable_get(:@strategies)).to be_empty
    end

    it 'returns empty hash after clearing' do
      expect(registry.clear).to be_empty
    end
  end
end
