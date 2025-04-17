# frozen_string_literal: true

require 'spec_helper'
require 'active_job'

RSpec.describe TypeBalancer::Rails::BalanceCalculationJob do
  let(:model_class) do
    mock_model_class('Post').tap do |klass|
      allow(klass).to receive(:model_name).and_return(
        ActiveModel::Name.new(klass, nil, 'Post')
      )
    end
  end

  let(:relation) do
    instance_double(ActiveRecord::Relation).tap do |double|
      allow(double).to receive_messages(klass: model_class, cache_key_with_version: 'posts/123-20230401')
    end
  end

  let(:position_manager) do
    instance_double(TypeBalancer::Rails::BackgroundPositionManager).tap do |double|
      allow(double).to receive(:fetch_or_calculate).with(relation).and_return({ 1 => 1, 2 => 2 })
    end
  end

  let(:storage_strategy) do
    instance_double(TypeBalancer::Rails::Strategies::BaseStrategy).tap do |double|
      allow(double).to receive(:store)
    end
  end

  before do
    allow(TypeBalancer::Rails::BackgroundPositionManager).to receive(:new).and_return(position_manager)
    allow(TypeBalancer::Rails).to receive_message_chain(:configuration, :storage_strategy).and_return(storage_strategy)
  end

  describe '#perform' do
    it 'calculates and stores positions using the position manager' do
      expect(position_manager).to receive(:fetch_or_calculate).with(relation)
      expect(storage_strategy).to receive(:store).with(
        'type_balancer/posts/posts/123-20230401',
        { 1 => 1, 2 => 2 }
      )

      described_class.perform_now(relation, {})
    end

    context 'when position calculation fails' do
      before do
        allow(position_manager).to receive(:fetch_or_calculate).and_raise('Position calculation error')
      end

      it 'raises the error' do
        expect do
          described_class.perform_now(relation, {})
        end.to raise_error('Position calculation error')
      end
    end

    context 'when storage fails' do
      before do
        allow(storage_strategy).to receive(:store).and_raise('Storage error')
      end

      it 'raises the error' do
        expect do
          described_class.perform_now(relation, {})
        end.to raise_error('Storage error')
      end
    end
  end

  describe '#generate_cache_key' do
    it 'generates a cache key using model name and version' do
      job = described_class.new
      cache_key = job.send(:generate_cache_key, relation)
      expect(cache_key).to eq('type_balancer/posts/posts/123-20230401')
    end
  end
end
