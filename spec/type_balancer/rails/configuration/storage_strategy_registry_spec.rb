# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Configuration::StorageStrategyRegistry do
  let(:registry) { described_class.new }

  describe '#initialize' do
    it 'creates an empty registry' do
      expect(registry.registered_strategies).to be_empty
    end
  end

  describe '#register' do
    let(:test_strategy) { double('TestStrategy') }

    it 'registers a strategy with a string name' do
      registry.register('test', test_strategy)
      expect(registry.resolve(:test)).to eq(test_strategy)
    end

    it 'registers a strategy with a symbol name' do
      registry.register(:test, test_strategy)
      expect(registry.resolve(:test)).to eq(test_strategy)
    end

    it 'overwrites existing strategy with same name' do
      other_strategy = double('OtherStrategy')
      registry.register(:test, test_strategy)
      registry.register(:test, other_strategy)
      expect(registry.resolve(:test)).to eq(other_strategy)
    end
  end

  describe '#resolve' do
    let(:test_strategy) { double('TestStrategy') }

    before do
      registry.register(:test, test_strategy)
    end

    it 'resolves registered strategy by symbol' do
      expect(registry.resolve(:test)).to eq(test_strategy)
    end

    it 'raises KeyError for unknown strategy' do
      expect { registry.resolve(:unknown) }.to raise_error(
        KeyError,
        'Unknown storage strategy: unknown'
      )
    end
  end

  describe '#registered_strategies' do
    it 'returns empty array for new registry' do
      expect(registry.registered_strategies).to be_empty
    end

    it 'returns array of registered strategy names as symbols' do
      strategy1 = double('Strategy1')
      strategy2 = double('Strategy2')
      registry.register(:test1, strategy1)
      registry.register(:test2, strategy2)
      expect(registry.registered_strategies).to contain_exactly(:test1, :test2)
    end
  end

  describe '#reset!' do
    let(:strategy1) { double('Strategy1') }
    let(:strategy2) { double('Strategy2') }

    before do
      registry.register(:test1, strategy1)
      registry.register(:test2, strategy2)
    end

    it 'removes all registered strategies' do
      registry.reset!
      expect(registry.registered_strategies).to be_empty
    end

    it 'allows registering new strategies after reset' do
      registry.reset!
      new_strategy = double('NewStrategy')
      registry.register(:new, new_strategy)
      expect(registry.resolve(:new)).to eq(new_strategy)
    end
  end
end 