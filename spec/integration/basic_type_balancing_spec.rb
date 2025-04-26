# frozen_string_literal: true

require 'spec_helper'
require 'integration_helper'

RSpec.describe 'Basic Type Balancing', :integration do
  let(:records) do
    [
      OpenStruct.new(id: 1, type: 'post', title: 'First Post'),
      OpenStruct.new(id: 2, type: 'video', title: 'First Video'),
      OpenStruct.new(id: 3, type: 'post', title: 'Second Post')
    ]
  end

  let(:relation) { TestRelation.new(records) }

  before do
    allow(TypeBalancer).to receive(:balance).and_return(records)
    TestModel.test_records = records
  end

  describe '#balance_by_type' do
    it 'balances records by type using default settings' do
      expect(TypeBalancer).to receive(:balance).with(
        records,
        type_field: :type
      ).and_return(records)

      result = relation.balance_by_type
      expect(result).to be_a(TestRelation)
      expect(result.to_a).to eq(records)
    end

    it 'allows overriding the type field' do
      expect(TypeBalancer).to receive(:balance).with(
        records,
        type_field: :category
      ).and_return(records)

      relation.balance_by_type(type_field: :category)
    end

    it 'preserves order of balanced records' do
      ordered_records = records.reverse
      allow(TypeBalancer).to receive(:balance).and_return(ordered_records)

      result = relation.order(id: :desc).balance_by_type
      expect(result.to_a).to eq(ordered_records)
    end

    it 'handles pagination after balancing' do
      paginated_records = [records[1]] # Just the video
      allow(TypeBalancer).to receive(:balance).and_return(paginated_records)

      result = relation.balance_by_type.limit(1).offset(1)
      expect(result.to_a).to eq(paginated_records)
    end

    it 'handles empty result sets' do
      empty_relation = TestRelation.new([])
      allow(TypeBalancer).to receive(:balance).with(
        [],
        type_field: :type
      ).and_return([])

      result = empty_relation.balance_by_type
      expect(result).to be_a(TestRelation)
      expect(result.to_a).to be_empty
    end

    it 'handles pagination' do
      result = relation.balance_by_type(page: 2, per_page: 1)
      expect(result.to_a.length).to eq(1)
    end
  end
end
