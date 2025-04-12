# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Config::StrategyManager do
  let(:valid_strategy_class) do
    Class.new(TypeBalancer::Rails::Storage::BaseStorage) do
      def store(key, value); end
      def fetch(key); end
      def delete(key); end
      def clear; end
    end
  end

  before do
    described_class.reset!
  end

  describe '.register' do
    it 'registers a valid strategy' do
      expect {
        described_class.register(:test, valid_strategy_class)
      }.not_to raise_error

      expect(described_class.available_strategies).to include(:test)
    end

    it 'raises error for invalid strategy' do
      invalid_strategy = Class.new

      expect {
        described_class.register(:invalid, invalid_strategy)
      }.to raise_error(described_class::InvalidStrategyError)
    end
  end

  describe '.resolve' do
    before do
      described_class.register(:test, valid_strategy_class)
    end

    it 'resolves registered strategy' do
      expect(described_class.resolve(:test)).to eq valid_strategy_class
    end

    it 'raises error for unknown strategy' do
      expect {
        described_class.resolve(:unknown)
      }.to raise_error(described_class::UnknownStrategyError)
    end
  end

  describe '.available_strategies' do
    before do
      described_class.register(:strategy1, valid_strategy_class)
      described_class.register(:strategy2, valid_strategy_class)
    end

    it 'returns list of registered strategies' do
      expect(described_class.available_strategies).to match_array([:strategy1, :strategy2])
    end
  end

  describe '.reset!' do
    before do
      described_class.register(:test, valid_strategy_class)
    end

    it 'clears all registered strategies' do
      described_class.reset!
      expect(described_class.available_strategies).to be_empty
    end
  end
end 