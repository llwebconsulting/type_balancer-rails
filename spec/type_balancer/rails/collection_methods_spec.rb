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
          OpenStruct.new(id: 1, type: 'Post', title: 'A', extra: 'foo'),
          OpenStruct.new(id: 2, type: 'Article', title: 'B', extra: 'bar'),
          OpenStruct.new(id: 3, type: 'Post', title: 'C', extra: 'baz')
        ]
      end

      it 'sends only id and type to TypeBalancer.balance with default type field' do
        expected_hashes = records.map { |r| { id: r.id, type: r.type } }
        expect(TypeBalancer).to receive(:balance) do |arg, type_field:|
          expect(arg).to all(include(:id, :type))
          expect(arg).to all(satisfy { |h| h.keys.sort == [:id, :type] })
          expect(type_field).to eq(:type)
          expected_hashes
        end
        relation.balance_by_type
      end

      it 'sends only id and custom type field to TypeBalancer.balance' do
        custom_records = [
          OpenStruct.new(id: 1, category: 'foo', title: 'A'),
          OpenStruct.new(id: 2, category: 'bar', title: 'B')
        ]
        custom_relation = TestRelation.new(custom_records)
        custom_relation.extend(described_class)
        expected_hashes = custom_records.map { |r| { id: r.id, type: r.category } }
        expect(TypeBalancer).to receive(:balance) do |arg, type_field:|
          expect(arg).to all(include(:id, :type))
          expect(arg.map { |h| h[:type] }).to eq(custom_records.map { |r| r.category })
          expect(type_field).to eq(:type)
          expected_hashes
        end
        custom_relation.balance_by_type(type_field: :category)
      end

      it 'delegates to TypeBalancer.balance with default type field' do
        expected_hashes = records.map { |r| { id: r.id, type: r.type } }
        expect(TypeBalancer).to receive(:balance) do |arg, type_field:|
          expect(arg).to all(include(:id, :type))
          expect(arg).to all(satisfy { |h| h.keys.sort == [:id, :type] })
          expect(type_field).to eq(:type)
          expected_hashes
        end
        relation.balance_by_type
      end

      it 'allows overriding the type field' do
        custom_records = [
          OpenStruct.new(id: 1, content_type: 'foo', title: 'A'),
          OpenStruct.new(id: 2, content_type: 'bar', title: 'B'),
          OpenStruct.new(id: 3, content_type: 'baz', title: 'C')
        ]
        custom_relation = TestRelation.new(custom_records)
        custom_relation.extend(described_class)
        expected_hashes = custom_records.map { |r| { id: r.id, type: r.content_type } }
        expect(TypeBalancer).to receive(:balance) do |arg, type_field:|
          expect(arg).to all(include(:id, :type))
          expect(arg.map { |h| h[:type] }).to eq(custom_records.map { |r| r.content_type })
          expect(type_field).to eq(:type)
          expected_hashes
        end
        custom_relation.balance_by_type(type_field: :content_type)
      end

      context 'with pagination' do
        let(:paginated_records) { records.first(2) }

        before do
          allow(relation).to receive(:limit).and_return(TestRelation.new(paginated_records))
        end

        it 'preserves pagination' do
          expected_hashes = paginated_records.map { |r| { id: r.id, type: r.type } }
          expect(TypeBalancer).to receive(:balance) do |arg, type_field:|
            expect(arg).to all(include(:id, :type))
            expect(arg).to all(satisfy { |h| h.keys.sort == [:id, :type] })
            expect(type_field).to eq(:type)
            expected_hashes
          end
          relation.limit(2).balance_by_type
        end
      end

      it 'returns records in the order of ids returned by the balancer (flat array)' do
        # Setup: balancer returns hashes in a custom order
        balanced_hashes = [
          { id: 2, type: 'Article' },
          { id: 1, type: 'Post' },
          { id: 3, type: 'Post' }
        ]
        allow(TypeBalancer).to receive(:balance).and_return(balanced_hashes)
        # The original records are:
        # 1: Post, 2: Article, 3: Post
        expected_order = [records[1], records[0], records[2]]
        result = relation.balance_by_type
        expect(result.to_a).to eq(expected_order)
      end

      it 'returns records in the order of ids returned by the balancer (nested array)' do
        # Setup: balancer returns nested arrays of hashes
        balanced_hashes = [
          [{ id: 3, type: 'Post' }],
          [{ id: 1, type: 'Post' }, { id: 2, type: 'Article' }]
        ]
        allow(TypeBalancer).to receive(:balance).and_return(balanced_hashes)
        # Flattened order: 3, 1, 2
        expected_order = [records[2], records[0], records[1]]
        result = relation.balance_by_type
        expect(result.to_a).to eq(expected_order)
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
