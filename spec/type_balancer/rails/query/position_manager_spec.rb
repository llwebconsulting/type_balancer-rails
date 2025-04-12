# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Query::PositionManager do
  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'posts'
      
      def self.column_names
        ['id', 'title', 'media_type']
      end
    end
  end

  let(:record1) { model_class.new(id: 1, media_type: 'video') }
  let(:record2) { model_class.new(id: 2, media_type: 'image') }
  let(:record3) { model_class.new(id: 3, media_type: 'video') }
  let(:record4) { model_class.new(id: 4, media_type: 'article') }

  let(:base_scope) do
    scope = model_class.all
    allow(scope).to receive(:count).and_return(4)
    allow(scope).to receive(:to_a).and_return([record1, record2, record3, record4])
    scope
  end

  let(:storage_strategy) { instance_double('TypeBalancer::Rails::StorageStrategies::BaseStrategy') }
  let(:default_options) { { type_field: :media_type, storage: storage_strategy } }
  
  subject(:manager) { described_class.new(base_scope, default_options) }

  describe '#initialize' do
    it 'accepts a scope and options' do
      expect { described_class.new(base_scope, default_options) }.not_to raise_error
    end

    it 'uses default storage when not provided' do
      allow(TypeBalancer::Rails::Container).to receive(:resolve)
        .with(:default_storage_strategy)
        .and_return(storage_strategy)
      
      manager = described_class.new(base_scope, type_field: :media_type)
      expect(manager.send(:storage)).to eq(storage_strategy)
    end

    it 'validates storage strategy type' do
      invalid_storage = Object.new
      expect {
        described_class.new(base_scope, type_field: :media_type, storage: invalid_storage)
      }.to raise_error(ArgumentError, /must be a storage strategy/)
    end
  end

  describe '#calculate_positions' do
    before do
      allow(base_scope).to receive(:group_by).and_call_original
      allow(storage_strategy).to receive(:store)
    end

    it 'validates the scope' do
      expect { manager.calculate_positions }.not_to raise_error
    end

    it 'raises error for nil scope' do
      manager = described_class.new(nil, default_options)
      expect { manager.calculate_positions }.to raise_error(ArgumentError, 'Scope cannot be nil')
    end

    it 'raises error for invalid scope type' do
      manager = described_class.new('invalid', default_options)
      expect { manager.calculate_positions }.to raise_error(ArgumentError, 'Scope must be an ActiveRecord::Relation')
    end

    it 'raises error when type field is not specified' do
      manager = described_class.new(base_scope, {})
      expect { manager.calculate_positions }.to raise_error(ArgumentError, 'Type field must be specified')
    end

    it 'groups records by type and balances them' do
      positions = manager.calculate_positions
      expect(positions.map(&:media_type)).to eq(['video', 'image', 'video', 'article'])
    end

    it 'stores calculated positions' do
      positions = manager.calculate_positions
      
      expect(storage_strategy).to have_received(:store).exactly(4).times
      positions.each_with_index do |record, index|
        expect(storage_strategy).to have_received(:store).with(
          "position:#{record.id}",
          {
            record_id: record.id,
            record_type: model_class.name,
            position: index + 1,
            type_field: :media_type,
            type_value: record.media_type
          },
          ttl: nil
        )
      end
    end

    context 'with custom order' do
      let(:options) { default_options.merge(order: ['article', 'image', 'video']) }
      
      it 'respects the specified order' do
        positions = manager.calculate_positions
        first_types = positions.take(3).map(&:media_type)
        expect(first_types).to eq(['article', 'image', 'video'])
      end
    end

    context 'with alphabetical ordering' do
      let(:options) { default_options.merge(order_alphabetically: true) }
      
      it 'orders types alphabetically' do
        positions = manager.calculate_positions
        first_types = positions.take(3).map(&:media_type)
        expect(first_types).to eq(['article', 'image', 'video'])
      end
    end

    context 'with TTL option' do
      let(:options) { default_options.merge(ttl: 1.hour) }

      it 'passes TTL to storage strategy' do
        positions = manager.calculate_positions
        
        positions.each do |record|
          expect(storage_strategy).to have_received(:store).with(
            "position:#{record.id}",
            anything,
            ttl: 1.hour
          )
        end
      end
    end
  end

  describe '#store_positions' do
    let(:positions) { [record1, record2, record3, record4] }

    before do
      allow(storage_strategy).to receive(:store)
    end

    it 'stores each position with the correct attributes' do
      manager.store_positions(positions)

      expect(storage_strategy).to have_received(:store).exactly(4).times
      expect(storage_strategy).to have_received(:store).with(
        "position:1",
        {
          record_id: 1,
          record_type: model_class.name,
          position: 1,
          type_field: :media_type,
          type_value: 'video'
        },
        ttl: nil
      )
    end

    context 'with TTL option' do
      let(:options) { default_options.merge(ttl: 2.hours) }

      it 'passes TTL to storage strategy' do
        manager.store_positions(positions)
        
        positions.each_with_index do |record, index|
          expect(storage_strategy).to have_received(:store).with(
            "position:#{record.id}",
            anything,
            ttl: 2.hours
          )
        end
      end
    end
  end

  describe '#fetch_positions' do
    let(:stored_positions) do
      [
        { record_id: 1, position: 1, type_value: 'video' },
        { record_id: 2, position: 2, type_value: 'image' }
      ]
    end

    before do
      allow(storage_strategy).to receive(:fetch_for_scope)
        .with(base_scope)
        .and_return(stored_positions)
    end

    it 'delegates to storage strategy' do
      positions = manager.fetch_positions
      expect(positions).to eq(stored_positions)
      expect(storage_strategy).to have_received(:fetch_for_scope).with(base_scope)
    end
  end

  describe '#clear_positions' do
    before do
      allow(storage_strategy).to receive(:clear_for_scope).with(base_scope)
    end

    it 'delegates to storage strategy' do
      manager.clear_positions
      expect(storage_strategy).to have_received(:clear_for_scope).with(base_scope)
    end
  end
end 