# frozen_string_literal: true

require 'spec_helper'
require 'integration_helper'

# We're using string references for class_double and instance_double of 'MyModel'
# throughout this file because it's a non-existent class used only for testing the interface
# rubocop:disable RSpec/VerifiedDoubleReference
RSpec.describe 'Basic Type Balancing', :integration do
  let(:records) do
    [
      OpenStruct.new(id: 1, type: 'post', title: 'First Post'),
      OpenStruct.new(id: 2, type: 'video', title: 'First Video'),
      OpenStruct.new(id: 3, type: 'post', title: 'Second Post')
    ]
  end

  let(:klass) { class_double('MyModel', name: 'MyModel') }
  let(:empty_relation) do
    rel = instance_double(ActiveRecord::Relation)
    rel.extend(TypeBalancer::Rails::CollectionMethods)
    allow(rel).to receive(:to_a).and_return([])
    allow(rel).to receive(:klass).and_return(klass)
    allow(rel).to receive(:class).and_return(ActiveRecord::Relation)
    allow(rel).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
    allow(rel).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
    allow(rel).to receive(:order).and_return(rel)
    allow(klass).to receive(:none).and_return(rel)
    rel
  end

  let(:relation) do
    rel = instance_double(ActiveRecord::Relation)
    rel.extend(TypeBalancer::Rails::CollectionMethods)
    allow(rel).to receive(:to_a).and_return(records)
    allow(rel).to receive(:klass).and_return(klass)
    allow(rel).to receive(:class).and_return(ActiveRecord::Relation)
    allow(rel).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
    allow(rel).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
    allow(klass).to receive(:name).and_return('MyModel')
    allow(klass).to receive(:where).with(id: [1, 2, 3]).and_return(rel)
    allow(rel).to receive(:order).and_return(rel)
    allow(klass).to receive(:none).and_return(empty_relation)
    rel
  end

  before do
    allow(TypeBalancer).to receive(:balance).and_return(records)
    # TestModel.test_records = records # Remove if not needed for double-based tests
  end

  describe '#balance_by_type' do
    it 'balances records by type using default settings' do
      expected_hashes = records.map { |r| { id: r.id, type: r.type } }
      expect(TypeBalancer).to receive(:balance).with(
        expected_hashes,
        type_field: :type,
        type_order: ['video', 'post']
      ).and_return(records)
      allow(klass).to receive(:where).with(id: [1, 2, 3]).and_return(relation)
      allow(relation).to receive(:order).and_return(relation)
      allow(relation).to receive(:to_a).and_return(records)
      result = relation.balance_by_type
      expect(result.to_a).to eq(records)
    end

    it 'allows overriding the type field' do
      custom_records = [
        OpenStruct.new(id: 1, category: 'foo', title: 'First Post'),
        OpenStruct.new(id: 2, category: 'bar', title: 'First Video'),
        OpenStruct.new(id: 3, category: 'baz', title: 'Second Post')
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
      ).and_return(custom_records)
      allow(custom_klass).to receive(:where).with(id: [1, 2, 3]).and_return(custom_relation)
      allow(custom_relation).to receive(:order).and_return(custom_relation)
      allow(custom_relation).to receive(:to_a).and_return(custom_records)
      custom_relation.balance_by_type(type_field: :category)
    end

    it 'preserves order of balanced records' do
      ordered_records = records.reverse
      allow(TypeBalancer).to receive(:balance).and_return(ordered_records)
      allow(klass).to receive(:where).with(id: [3, 2, 1]).and_return(relation)
      allow(relation).to receive(:order).and_return(relation)
      allow(relation).to receive(:to_a).and_return(ordered_records)
      allow(relation).to receive(:order).with(id: :desc).and_return(relation)
      result = relation.order(id: :desc).balance_by_type
      expect(result.to_a).to eq(ordered_records)
    end

    it 'handles pagination after balancing' do
      paginated_records = [records[1]] # Just the video
      allow(TypeBalancer).to receive(:balance).and_return(paginated_records)
      allow(klass).to receive(:where).with(id: [2]).and_return(relation)
      allow(relation).to receive(:order).and_return(relation)
      allow(relation).to receive(:to_a).and_return(paginated_records)
      allow(relation).to receive(:limit).with(1).and_return(relation)
      allow(relation).to receive(:offset).with(1).and_return(relation)
      result = relation.balance_by_type.limit(1).offset(1)
      expect(result.to_a).to eq(paginated_records)
    end

    it 'handles empty result sets' do
      result = empty_relation.balance_by_type
      expect(result.to_a).to be_empty
    end

    it 'handles pagination' do
      allow(klass).to receive(:where).with(id: [1]).and_return(relation)
      allow(relation).to receive(:order).and_return(relation)
      allow(relation).to receive(:to_a).and_return([records[0]])
      result = relation.balance_by_type(page: 1, per_page: 1)
      expect(result.to_a.length).to eq(1)
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubleReference
