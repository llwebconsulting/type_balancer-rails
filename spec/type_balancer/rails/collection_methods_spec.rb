# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::CollectionMethods, :unit do
  # rubocop:disable RSpec/VerifiedDoubleReference
  let(:model_class) { class_double('MyModel') }
  # rubocop:enable RSpec/VerifiedDoubleReference
  let(:relation) do
    rel = double('ActiveRecord::Relation')
    rel.extend(described_class)
    allow(rel).to receive(:klass).and_return(model_class)
    allow(rel).to receive(:to_sql).and_return('SELECT * FROM my_models')
    rel
  end

  before do
    # Use a simple in-memory cache for tests
    cache = Class.new do
      def initialize = @store = {}

      def fetch(key, _options = {})
        @store[key] ||= yield
      end
    end.new
    allow(TypeBalancer::Rails).to receive(:cache_adapter).and_return(cache)
    allow(model_class).to receive(:where) { relation }
    allow(model_class).to receive(:none) { double('EmptyRelation', to_a: [], klass: model_class) }
  end

  it 'returns a relation with records balanced by type (default field)' do
    records = [OpenStruct.new(id: 1, type: 'A'), OpenStruct.new(id: 2, type: 'B'), OpenStruct.new(id: 3, type: 'A')]
    allow(relation).to receive(:select).with(:id, :type).and_return(records)
    allow(TypeBalancer).to receive(:balance).and_return([{ id: 2, type: 'B' }, { id: 1, type: 'A' },
                                                         { id: 3, type: 'A' }])
    ordered = [records[1], records[0], records[2]]
    allow(model_class).to receive(:where).with(id: [2, 1, 3]).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(ordered)
    result = relation.balance_by_type
    expect(result.to_a).to eq(ordered)
  end

  it 'returns a relation with records balanced by a custom type field' do
    records = [OpenStruct.new(id: 1, category: 'foo'), OpenStruct.new(id: 2, category: 'bar')]
    allow(relation).to receive(:select).with(:id, :category).and_return(records)
    allow(TypeBalancer).to receive(:balance).and_return([{ id: 2, category: 'bar' }, { id: 1, category: 'foo' }])
    ordered = [records[1], records[0]]
    allow(model_class).to receive(:where).with(id: [2, 1]).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(ordered)
    result = relation.balance_by_type(type_field: :category)
    expect(result.to_a).to eq(ordered)
  end

  it 'returns only the correct page of records (pagination)' do
    records = (1..10).map { |i| OpenStruct.new(id: i, type: 'A') }
    allow(relation).to receive(:select).with(:id, :type).and_return(records)
    allow(TypeBalancer).to receive(:balance).and_return(records.map { |r| { id: r.id, type: r.type } })
    page_ids = (4..6).to_a
    paged = records[3..5]
    allow(model_class).to receive(:where).with(id: page_ids).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(paged)
    result = relation.balance_by_type(page: 2, per_page: 3)
    expect(result.to_a).to eq(paged)
  end

  it 'returns an empty relation if there are no records' do
    allow(relation).to receive(:select).with(:id, :type).and_return([])
    empty_rel = double('EmptyRelation', to_a: [], klass: model_class)
    allow(model_class).to receive(:none).and_return(empty_rel)
    result = relation.balance_by_type
    expect(result.to_a).to eq([])
  end

  it 'returns an empty relation if TypeBalancer.balance returns nil' do
    records = [OpenStruct.new(id: 1, type: 'A')]
    allow(relation).to receive(:select).with(:id, :type).and_return(records)
    allow(TypeBalancer).to receive(:balance).and_return(nil)
    empty_rel = double('EmptyRelation', to_a: [], klass: model_class)
    allow(model_class).to receive(:none).and_return(empty_rel)
    result = relation.balance_by_type
    expect(result.to_a).to eq([])
  end

  it 'returns records in the order determined by the balancer' do
    records = [OpenStruct.new(id: 1, type: 'A'), OpenStruct.new(id: 2, type: 'B'), OpenStruct.new(id: 3, type: 'A')]
    allow(relation).to receive(:select).with(:id, :type).and_return(records)
    allow(TypeBalancer).to receive(:balance).and_return([{ id: 3, type: 'A' }, { id: 2, type: 'B' },
                                                         { id: 1, type: 'A' }])
    ordered = [records[2], records[1], records[0]]
    allow(model_class).to receive(:where).with(id: [3, 2, 1]).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(ordered)
    result = relation.balance_by_type
    expect(result.to_a).to eq(ordered)
  end

  it 'caches the balanced ID list and reuses it' do
    records = [OpenStruct.new(id: 1, type: 'A'), OpenStruct.new(id: 2, type: 'B')]
    allow(relation).to receive(:select).with(:id, :type).and_return(records)
    allow(TypeBalancer).to receive(:balance).once.and_return([{ id: 2, type: 'B' }, { id: 1, type: 'A' }])
    ordered = [records[1], records[0]]
    allow(model_class).to receive(:where).with(id: [2, 1]).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(ordered)
    2.times { relation.balance_by_type }
    expect(TypeBalancer).to have_received(:balance).once
  end

  it 'handles a single type' do
    records = [OpenStruct.new(id: 1, type: 'A'), OpenStruct.new(id: 2, type: 'A')]
    allow(relation).to receive(:select).with(:id, :type).and_return(records)
    allow(TypeBalancer).to receive(:balance).and_return(records.map { |r| { id: r.id, type: r.type } })
    allow(model_class).to receive(:where).with(id: [1, 2]).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(records)
    result = relation.balance_by_type
    expect(result.to_a).to eq(records)
  end

  it 'handles multiple types with uneven distribution' do
    records = [OpenStruct.new(id: 1, type: 'A'), OpenStruct.new(id: 2, type: 'B'), OpenStruct.new(id: 3, type: 'A'),
               OpenStruct.new(id: 4, type: 'B'), OpenStruct.new(id: 5, type: 'A')]
    allow(relation).to receive(:select).with(:id, :type).and_return(records)
    allow(TypeBalancer).to receive(:balance)
                       .and_return(
                         [
                           { id: 2, type: 'B' },
                           { id: 1, type: 'A' },
                           { id: 4, type: 'B' },
                           { id: 3, type: 'A' },
                           { id: 5, type: 'A' }
                         ]
                       )
    ordered = [records[1], records[0], records[3], records[2], records[4]]
    allow(model_class).to receive(:where)
                      .with(id: [2, 1, 4, 3, 5])
      .and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(ordered)
    result = relation.balance_by_type
    expect(result.to_a).to eq(ordered)
  end
end
