# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::CollectionMethods, :unit do
  let(:relation) { TestRelation.new(records) }
  let(:records) { [] }

  before do
    relation.extend(described_class)
  end

  describe '#balance_by_type' do
    context 'with an empty relation' do
      it 'returns an empty relation' do
        result = relation.balance_by_type
        expect(result).to be_a(TestRelation)
        expect(result.to_a).to be_empty
      end
    end

    context 'with records' do
      let(:records) do
        [
          OpenStruct.new(id: 1, type: 'Post'),
          OpenStruct.new(id: 2, type: 'Article'),
          OpenStruct.new(id: 3, type: 'Post')
        ]
      end

      it 'delegates to TypeBalancer.balance with default type field' do
        expect(TypeBalancer).to receive(:balance).with(records, type_field: :type)
        relation.balance_by_type
      end

      it 'allows overriding the type field' do
        expect(TypeBalancer).to receive(:balance).with(records, type_field: :content_type)
        relation.balance_by_type(type_field: :content_type)
      end

      context 'with pagination' do
        let(:paginated_records) { records.first(2) }

        before do
          allow(relation).to receive(:limit).and_return(TestRelation.new(paginated_records))
        end

        it 'preserves pagination' do
          expect(TypeBalancer).to receive(:balance).with(paginated_records, type_field: :type)
          relation.limit(2).balance_by_type
        end
      end
    end
  end

  describe 'edge cases and coverage' do
    it 'returns empty relation if records are empty' do
      relation = TestRelation.new([])
      result = relation.balance_by_type
      expect(result).to be_empty
    end

    it 'returns empty relation if TypeBalancer.balance returns nil' do
      relation = TestRelation.new([OpenStruct.new(id: 1, type: 'Post')])
      allow(TypeBalancer).to receive(:balance).and_return(nil)
      result = relation.balance_by_type
      expect(result).to be_empty
    end

    it 'returns all records if no pagination options are given' do
      records = [OpenStruct.new(id: 1, type: 'post', title: 'First Post')]
      relation = TestRelation.new(records)
      allow(TypeBalancer).to receive(:balance).and_return(records)
      result = relation.balance_by_type
      expect(result.to_a).to eq(records)
    end

    it 'returns paginated records if pagination options are given' do
      records = [
        OpenStruct.new(id: 1, type: 'post', title: 'First Post'),
        OpenStruct.new(id: 2, type: 'video', title: 'First Video')
      ]
      relation = TestRelation.new(records)
      allow(TypeBalancer).to receive(:balance).and_return(records)
      result = relation.balance_by_type(page: 2, per_page: 1)
      expect(result.to_a).to eq([records[1]])
    end
  end
end
