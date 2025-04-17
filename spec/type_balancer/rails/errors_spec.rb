# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Errors do
  describe 'error hierarchy' do
    it 'ensures Error inherits from StandardError' do
      expect(described_class::Error).to be < StandardError
    end

    it 'ensures ConfigurationError inherits from Error' do
      expect(described_class::ConfigurationError).to be < described_class::Error
    end

    it 'ensures StrategyError inherits from Error' do
      expect(described_class::StrategyError).to be < described_class::Error
    end

    it 'ensures CacheError inherits from Error' do
      expect(described_class::CacheError).to be < described_class::Error
    end

    it 'ensures RedisError inherits from Error' do
      expect(described_class::RedisError).to be < described_class::Error
    end

    it 'ensures ValidationError inherits from Error' do
      expect(described_class::ValidationError).to be < described_class::Error
    end

    it 'ensures DependencyError inherits from Error' do
      expect(described_class::DependencyError).to be < described_class::Error
    end
  end

  describe 'error instantiation' do
    it 'can instantiate Error with a message' do
      error = described_class::Error.new('test message')
      expect(error.message).to eq('test message')
    end

    it 'can instantiate ConfigurationError with a message' do
      error = described_class::ConfigurationError.new('test message')
      expect(error.message).to eq('test message')
    end

    it 'can instantiate StrategyError with a message' do
      error = described_class::StrategyError.new('test message')
      expect(error.message).to eq('test message')
    end

    it 'can instantiate CacheError with a message' do
      error = described_class::CacheError.new('test message')
      expect(error.message).to eq('test message')
    end

    it 'can instantiate RedisError with a message' do
      error = described_class::RedisError.new('test message')
      expect(error.message).to eq('test message')
    end

    it 'can instantiate ValidationError with a message' do
      error = described_class::ValidationError.new('test message')
      expect(error.message).to eq('test message')
    end

    it 'can instantiate DependencyError with a message' do
      error = described_class::DependencyError.new('test message')
      expect(error.message).to eq('test message')
    end
  end

  describe 'error namespace' do
    it 'is properly namespaced under TypeBalancer::Rails::Errors' do
      expect(described_class.name).to eq('TypeBalancer::Rails::Errors')
    end
  end
end
