# frozen_string_literal: true

require 'spec_helper'

# We're using string references for class_double and instance_double of 'MyModel'
# throughout this file because it's a non-existent class used only for testing the interface
# rubocop:disable RSpec/VerifiedDoubleReference
RSpec.describe 'Model Configuration', :integration do
  let(:model_class) { class_double('MyModel') }
  let(:relation) do
    rel = double('ActiveRecord::Relation')
    rel.extend(TypeBalancer::Rails::CollectionMethods)
    allow(rel).to receive(:klass).and_return(model_class)
    allow(rel).to receive(:to_sql).and_return('SELECT * FROM my_models')
    rel
  end

  before do
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

  it 'uses model-level configuration for type field' do
    records = [OpenStruct.new(id: 1, foo: 'A'), OpenStruct.new(id: 2, foo: 'B')]
    allow(model_class).to receive(:type_balancer_options).and_return({ type_field: :foo })
    allow(relation).to receive(:select).with(:id, :foo).and_return(records)
    allow(TypeBalancer).to receive(:balance).and_return([{ id: 2, foo: 'B' }, { id: 1, foo: 'A' }])
    ordered = [records[1], records[0]]
    allow(model_class).to receive(:where).with(id: [2, 1]).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(ordered)
    result = relation.balance_by_type
    expect(result.to_a).to eq(ordered)
  end

  it 'allows per-query override of type field' do
    records = [OpenStruct.new(id: 1, bar: 'X'), OpenStruct.new(id: 2, bar: 'Y')]
    allow(model_class).to receive(:type_balancer_options).and_return({ type_field: :foo })
    allow(relation).to receive(:select).with(:id, :bar).and_return(records)
    allow(TypeBalancer).to receive(:balance).and_return([{ id: 2, bar: 'Y' }, { id: 1, bar: 'X' }])
    ordered = [records[1], records[0]]
    allow(model_class).to receive(:where).with(id: [2, 1]).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(ordered)
    result = relation.balance_by_type(type_field: :bar)
    expect(result.to_a).to eq(ordered)
  end

  it 'returns an empty relation if there are no records' do
    allow(model_class).to receive(:type_balancer_options).and_return({ type_field: :foo })
    allow(relation).to receive(:select).with(:id, :foo).and_return([])
    empty_rel = double('EmptyRelation', to_a: [], klass: model_class)
    allow(model_class).to receive(:none).and_return(empty_rel)
    result = relation.balance_by_type
    expect(result.to_a).to eq([])
  end

  it 'returns an empty relation if TypeBalancer.balance returns nil' do
    records = [OpenStruct.new(id: 1, foo: 'A')]
    allow(model_class).to receive(:type_balancer_options).and_return({ type_field: :foo })
    allow(relation).to receive(:select).with(:id, :foo).and_return(records)
    allow(TypeBalancer).to receive(:balance).and_return(nil)
    empty_rel = double('EmptyRelation', to_a: [], klass: model_class)
    allow(model_class).to receive(:none).and_return(empty_rel)
    result = relation.balance_by_type
    expect(result.to_a).to eq([])
  end
end
# rubocop:enable RSpec/VerifiedDoubleReference
