# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails'

RSpec.describe TypeBalancer::Rails, :unit do
  after do
    described_class.cache_adapter = nil
    described_class.cache_expiry_seconds = nil
  end

  describe 'VERSION' do
    it 'has a version number' do
      expect(TypeBalancer::Rails::VERSION).not_to be_nil
    end

    it 'follows semantic versioning format' do
      version_pattern = /^\d+\.\d+\.\d+/ # Major.Minor.Patch
      version_pattern = /#{version_pattern}(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?/ # Optional pre-release
      version_pattern = /#{version_pattern}(?:\+[0-9A-Za-z-]+)?$/ # Optional build metadata
      expect(TypeBalancer::Rails::VERSION).to match(version_pattern)
    end

    it 'is a frozen string' do
      expect(TypeBalancer::Rails::VERSION).to be_frozen
    end

    it 'cannot be modified' do
      expect do
        TypeBalancer::Rails::VERSION << '.modified'
      end.to raise_error(FrozenError)
    end
  end

  it 'allows configuration via a block' do
    adapter = double('Adapter')
    described_class.configure do |config|
      config.cache_adapter = adapter
      config.cache_expiry_seconds = 123
    end
    expect(described_class.cache_adapter).to eq(adapter)
    expect(described_class.cache_expiry_seconds).to eq(123)
  end

  it 'is backward compatible with direct assignment' do
    adapter = double('Adapter2')
    described_class.cache_adapter = adapter
    described_class.cache_expiry_seconds = 456
    expect(described_class.cache_adapter).to eq(adapter)
    expect(described_class.cache_expiry_seconds).to eq(456)
  end
end
