# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Query::PositionManager do
  subject(:manager) { described_class.new(scope, 'model_type', storage_adapter, options) }

  let(:model_class) do
    mock_model_class('TestModel').tap do |klass|
      allow(klass).to receive_messages(type_field: 'model_type', column_names: %w[id model_type])
    end
  end

  let(:scope) do
    mock_active_record_relation(model_class, []).tap do |relation|
      allow(relation).to receive(:pluck).with(:id, 'model_type').and_return([
                                                                              [1, 'TypeA'],
                                                                              [2, 'TypeB'],
                                                                              [3, 'TypeA']
                                                                            ])
      allow(relation).to receive(:pluck).with(:id).and_return([1, 2, 3])
      allow(relation).to receive(:find) do |id|
        instance = model_class.new
        allow(instance).to receive(:id).and_return(id)
        allow(instance).to receive(:public_send).with('model_type').and_return(
          case id
          when 1 then 'TypeA'
          when 2 then 'TypeB'
          when 3 then 'TypeA'
          end
        )
        instance
      end
    end
  end

  let(:storage_adapter) do
    instance_double(TypeBalancer::Rails::Config::ConfigStorageAdapter).tap do |adapter|
      allow(adapter).to receive_messages(store: true, fetch: nil, delete: true, exists?: false)
    end
  end

  let(:options) { {} }

  describe '#initialize' do
    context 'with valid parameters' do
      it 'creates a new instance' do
        expect(manager).to be_a(described_class)
      end

      it 'sets up the attributes correctly' do
        expect(manager.scope).to eq(scope)
        expect(manager.type_field).to eq('model_type')
        expect(manager.storage_adapter).to eq(storage_adapter)
        expect(manager.options).to eq(options)
      end
    end

    context 'with nil scope' do
      let(:scope) { nil }

      it 'raises an error' do
        expect { manager }.to raise_error(ArgumentError, 'Scope cannot be nil')
      end
    end

    context 'with nil type field and no model type field' do
      subject(:manager) { described_class.new(scope, nil, storage_adapter) }

      before do
        allow(model_class).to receive_messages(type_field: nil, column_names: ['id'])
      end

      it 'raises an error' do
        expect { manager }.to raise_error(ArgumentError, 'Type field must be specified')
      end
    end

    context 'with nil type field but model has type field' do
      subject(:manager) { described_class.new(scope, nil, storage_adapter) }

      it 'uses the type field from the model class' do
        expect(manager.type_field).to eq('model_type')
      end
    end
  end

  describe '#calculate_positions' do
    context 'with default ordering' do
      it 'calculates positions based on type and order' do
        positions = manager.calculate_positions

        expect(positions[1]).to be < positions[2] # TypeA comes before TypeB
        expect(positions[1]).to be < positions[3] # Same type (TypeA), first comes before second
        expect(positions[2]).to be > positions[3] # TypeB comes after TypeA
      end
    end

    context 'with custom type order' do
      let(:options) { { order: %w[TypeB TypeA] } }

      it 'respects the custom order' do
        positions = manager.calculate_positions

        expect(positions[1]).to be > positions[2] # TypeA comes after TypeB
        expect(positions[2]).to be < positions[3] # TypeB comes before TypeA
      end
    end

    context 'with alphabetical ordering' do
      let(:options) { { alphabetical: true } }

      it 'orders types alphabetically' do
        positions = manager.calculate_positions

        expect(positions[1]).to be < positions[2] # TypeA comes before TypeB
        expect(positions[2]).to be > positions[3] # TypeB comes after TypeA
      end
    end

    context 'with invalid scope' do
      before do
        allow(scope).to receive(:respond_to?).with(:pluck).and_return(false)
      end

      it 'raises an error' do
        expect { manager.calculate_positions }.to raise_error(ArgumentError, 'Invalid scope')
      end
    end
  end

  describe '#store_positions' do
    let(:positions) { { 1 => 1000.001, 2 => 2000.001, 3 => 1000.002 } }

    it 'stores positions using the storage adapter' do
      manager.store_positions(positions)

      expect(storage_adapter).to have_received(:store).exactly(3).times
      expect(storage_adapter).to have_received(:store).with(
        key: 'test_models:1',
        value: {
          record_id: 1,
          record_type: 'TestModel',
          position: 1000.001,
          type_value: 'TypeA'
        },
        ttl: nil
      )
    end

    context 'with TTL option' do
      let(:options) { { ttl: 3600 } }

      it 'passes TTL to storage adapter' do
        manager.store_positions(positions)
        expect(storage_adapter).to have_received(:store).with(
          key: 'test_models:1',
          value: hash_including(position: 1000.001),
          ttl: 3600
        )
      end
    end
  end

  describe '#fetch_positions' do
    before do
      allow(storage_adapter).to receive(:fetch).with(key: 'test_models:1').and_return({ position: 1000.001 })
      allow(storage_adapter).to receive(:fetch).with(key: 'test_models:2').and_return({ position: 2000.001 })
      allow(storage_adapter).to receive(:fetch).with(key: 'test_models:3').and_return({ position: 1000.002 })
    end

    it 'retrieves positions from storage' do
      positions = manager.fetch_positions

      expect(positions).to eq({
                                1 => 1000.001,
                                2 => 2000.001,
                                3 => 1000.002
                              })
    end

    context 'when some positions are missing' do
      before do
        allow(storage_adapter).to receive(:fetch).with(key: 'test_models:2').and_return(nil)
      end

      it 'only includes found positions' do
        positions = manager.fetch_positions
        expect(positions).to eq({
                                  1 => 1000.001,
                                  3 => 1000.002
                                })
      end
    end
  end

  describe '#clear_positions' do
    it 'deletes positions from storage' do
      expect(storage_adapter).to receive(:delete).with(key: 'test_models:1')
      expect(storage_adapter).to receive(:delete).with(key: 'test_models:2')
      expect(storage_adapter).to receive(:delete).with(key: 'test_models:3')
      manager.clear_positions
    end
  end
end
