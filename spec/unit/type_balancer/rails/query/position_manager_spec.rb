# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Query::PositionManager do
  let(:record_class) do
    class_double('Post').tap do |klass|
      allow(klass).to receive(:name).and_return('Post')
    end
  end

  let(:record1) do
    instance_double('Post').tap do |record|
      allow(record).to receive(:id).and_return(1)
      allow(record).to receive(:class).and_return(record_class)
      allow(record).to receive(:public_send).with(:media_type).and_return('video')
    end
  end

  let(:record2) do
    instance_double('Post').tap do |record|
      allow(record).to receive(:id).and_return(2)
      allow(record).to receive(:class).and_return(record_class)
      allow(record).to receive(:public_send).with(:media_type).and_return('image')
    end
  end

  let(:record3) do
    instance_double('Post').tap do |record|
      allow(record).to receive(:id).and_return(3)
      allow(record).to receive(:class).and_return(record_class)
      allow(record).to receive(:public_send).with(:media_type).and_return('text')
    end
  end
  
  let(:scope) do
    instance_double('ActiveRecord::Relation',
                   is_a?: true,
                   count: 3,
                   to_a: [record1, record2, record3])
  end

  let(:storage) { instance_double('TypeBalancer::Rails::Strategies::BaseStrategy') }
  let(:options) { { storage: storage, type_field: :media_type } }

  subject(:manager) { described_class.new(scope, options) }

  describe '#initialize' do
    it 'sets scope and options' do
      expect(manager.send(:scope)).to eq scope
      expect(manager.send(:options)).to eq options
    end

    context 'when storage is not provided' do
      let(:options) { { type_field: :media_type } }
      let(:default_storage) { instance_double('TypeBalancer::Rails::Strategies::CursorStrategy') }

      before do
        allow(TypeBalancer::Rails::Strategies::CursorStrategy).to receive(:new).and_return(default_storage)
      end

      it 'uses default cursor strategy' do
        expect(manager.send(:storage)).to eq default_storage
      end
    end
  end

  describe '#calculate_positions' do
    let(:calculated_positions) { [record2, record1, record3] }

    before do
      allow(TypeBalancer).to receive(:calculate_positions)
        .with(collection: scope, options: options)
        .and_return(calculated_positions)
    end

    it 'validates scope before calculating' do
      expect(manager).to receive(:validate_scope!).ordered
      expect(TypeBalancer).to receive(:calculate_positions).ordered
      manager.calculate_positions
    end

    it 'delegates calculation to TypeBalancer' do
      expect(manager.calculate_positions).to eq calculated_positions
    end

    context 'with invalid scope' do
      let(:scope) { nil }

      it 'raises ArgumentError' do
        expect { manager.calculate_positions }
          .to raise_error(ArgumentError, 'Scope cannot be nil')
      end
    end

    context 'without type field' do
      let(:options) { { storage: storage } }

      it 'raises ArgumentError' do
        expect { manager.calculate_positions }
          .to raise_error(ArgumentError, 'Type field must be specified')
      end
    end
  end

  describe '#store_positions' do
    let(:positions) { [record1, record2, record3] }

    it 'stores each position with correct attributes' do
      expect(storage).to receive(:store).with(
        record_id: 1,
        record_type: 'Post',
        position: 1,
        type_field: :media_type,
        type_value: 'video'
      )

      expect(storage).to receive(:store).with(
        record_id: 2,
        record_type: 'Post',
        position: 2,
        type_field: :media_type,
        type_value: 'image'
      )

      expect(storage).to receive(:store).with(
        record_id: 3,
        record_type: 'Post',
        position: 3,
        type_field: :media_type,
        type_value: 'text'
      )

      manager.store_positions(positions)
    end
  end

  describe '#fetch_positions' do
    let(:stored_positions) { [record2, record1, record3] }

    it 'delegates to storage strategy' do
      expect(storage).to receive(:fetch_for_scope).with(scope).and_return(stored_positions)
      expect(manager.fetch_positions).to eq stored_positions
    end
  end

  describe '#clear_positions' do
    it 'delegates to storage strategy' do
      expect(storage).to receive(:clear_for_scope).with(scope)
      manager.clear_positions
    end
  end

  describe '#determine_type_order' do
    let(:available_types) { %w[video image text] }

    context 'with explicit order in options' do
      let(:options) { { storage: storage, type_field: :media_type, order: %w[image video text] } }

      it 'uses provided order' do
        expect(manager.send(:determine_type_order, available_types))
          .to eq %w[image video text]
      end
    end

    context 'with alphabetical ordering' do
      let(:options) { { storage: storage, type_field: :media_type, order_alphabetically: true } }

      it 'sorts types alphabetically' do
        expect(manager.send(:determine_type_order, available_types))
          .to eq %w[image text video]
      end
    end

    context 'without ordering options' do
      it 'preserves original order' do
        expect(manager.send(:determine_type_order, available_types))
          .to eq %w[video image text]
      end
    end
  end

  describe '#calculate_max_per_type' do
    let(:records_by_type) do
      {
        'video' => [record1, record1.clone],
        'image' => [record2],
        'text' => [record3, record3.clone, record3.clone]
      }
    end

    it 'returns the maximum count of records for any type' do
      expect(manager.send(:calculate_max_per_type, records_by_type)).to eq 3
    end

    context 'with empty records' do
      let(:records_by_type) { {} }

      it 'returns 0' do
        expect(manager.send(:calculate_max_per_type, records_by_type)).to eq 0
      end
    end
  end
end 