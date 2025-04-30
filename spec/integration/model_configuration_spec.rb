# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Model Configuration', :integration do
  let(:records) do
    [
      OpenStruct.new(id: 1, type: 'post', title: 'First Post'),
      OpenStruct.new(id: 2, type: 'video', title: 'First Video'),
      OpenStruct.new(id: 3, type: 'post', title: 'Second Post')
    ]
  end

  let(:klass) { class_double('MyModel', name: 'MyModel') }
  let(:relation) do
    rel = instance_double(ActiveRecord::Relation)
    allow(rel).to receive(:to_a).and_return(records)
    allow(rel).to receive(:klass).and_return(klass)
    allow(rel).to receive(:class).and_return(ActiveRecord::Relation)
    allow(klass).to receive(:name).and_return('MyModel')
    rel.extend(TypeBalancer::Rails::CollectionMethods)
    rel
  end

  before do
    allow(TypeBalancer).to receive(:balance).and_return(records)
    allow(klass).to receive(:where).with(id: [1, 2, 3]).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(records)
    allow(klass).to receive(:all).and_return(relation)
    stub_const('TestModel', klass)
  end

  it 'uses model-level configuration' do
    expected_hashes = records.map { |r| { id: r.id, type: r.type } }
    expect(TypeBalancer).to receive(:balance).with(
      expected_hashes,
      type_field: :type,
      type_order: ['video', 'post']
    )
    TestModel.all.balance_by_type
  end

  it 'allows overriding model configuration per-query' do
    custom_records = [
      OpenStruct.new(id: 1, category: 'foo', title: 'First'),
      OpenStruct.new(id: 2, category: 'bar', title: 'Second'),
      OpenStruct.new(id: 3, category: 'baz', title: 'Third')
    ]
    custom_klass = class_double('MyModel', name: 'MyModel')
    custom_relation = instance_double(ActiveRecord::Relation)
    allow(custom_relation).to receive(:to_a).and_return(custom_records)
    allow(custom_relation).to receive(:klass).and_return(custom_klass)
    allow(custom_relation).to receive(:class).and_return(ActiveRecord::Relation)
    allow(custom_klass).to receive(:name).and_return('MyModel')
    custom_relation.extend(TypeBalancer::Rails::CollectionMethods)
    expected_hashes = custom_records.map { |r| { id: r.id, category: r.category } }
    expect(TypeBalancer).to receive(:balance).with(
      expected_hashes,
      type_field: :category,
      type_order: ['foo', 'bar', 'baz']
    )
    allow(custom_klass).to receive(:where).with(id: [1, 2, 3]).and_return(custom_relation)
    allow(custom_relation).to receive(:order).and_return(custom_relation)
    allow(custom_relation).to receive(:to_a).and_return(custom_records)
    allow(custom_klass).to receive(:all).and_return(custom_relation)
    stub_const('TestModel', custom_klass)
    custom_relation.balance_by_type(type_field: :category)
  end
end
