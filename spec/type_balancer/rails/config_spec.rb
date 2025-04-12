# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Config do
  describe '.load!' do
    before do
      # Reset everything before each test
      TypeBalancer::Rails.reset!
    end

    it 'loads without errors' do
      expect { described_class.load! }.not_to raise_error
    end

    context 'when storage strategies are implemented' do
      before do
        # These tests will be uncommented once storage strategies are implemented
        # allow(described_class).to receive(:require_relative)
        # allow(TypeBalancer::Rails::Config::StrategyManager).to receive(:register)
      end

      it 'requires all components' do
        pending 'Storage strategies not yet implemented'
        described_class.load!
        # expect(described_class).to have_received(:require_relative).with('storage/redis_storage')
        # expect(described_class).to have_received(:require_relative).with('storage/cursor_storage')
      end

      it 'registers default strategies' do
        pending 'Storage strategies not yet implemented'
        described_class.load!
        # expect(TypeBalancer::Rails::Config::StrategyManager)
        #   .to have_received(:register).with(:redis, TypeBalancer::Rails::Storage::RedisStorage)
        # expect(TypeBalancer::Rails::Config::StrategyManager)
        #   .to have_received(:register).with(:cursor, TypeBalancer::Rails::Storage::CursorStorage)
      end
    end
  end
end 