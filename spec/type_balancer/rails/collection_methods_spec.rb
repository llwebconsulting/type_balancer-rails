# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::CollectionMethods, :unit do
  describe '#balance_by_type' do
    context 'with an empty relation' do
      it 'returns an empty relation' do
        records = []
        relation = instance_double(ActiveRecord::Relation)
        klass = class_double('MyModel', name: 'MyModel')
        relation.extend(TypeBalancer::Rails::CollectionMethods)
        allow(relation).to receive(:to_a).and_return(records)
        allow(relation).to receive(:klass).and_return(klass)
        allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
        allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
        allow(klass).to receive(:name).and_return('MyModel')
        allow(klass).to receive(:where).with(id: []).and_return(relation)
        allow(relation).to receive(:order).and_return(relation)
        allow(klass).to receive(:none).and_return(relation)
        result = relation.balance_by_type
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
        relation = instance_double(ActiveRecord::Relation)
        klass = class_double('MyModel', name: 'MyModel')
        relation.extend(TypeBalancer::Rails::CollectionMethods)
        allow(relation).to receive(:to_a).and_return(records)
        allow(relation).to receive(:klass).and_return(klass)
        allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
        allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
        allow(klass).to receive(:name).and_return('MyModel')
        allow(klass).to receive(:where).with(id: [1, 2, 3]).and_return(relation)
        allow(relation).to receive(:order).and_return(relation)
        allow(klass).to receive(:none).and_return(relation)
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
        custom_relation = instance_double(ActiveRecord::Relation)
        custom_klass = class_double('MyModel', name: 'MyModel')
        custom_relation.extend(TypeBalancer::Rails::CollectionMethods)
        allow(custom_relation).to receive(:to_a).and_return(custom_records)
        allow(custom_relation).to receive(:klass).and_return(custom_klass)
        allow(custom_relation).to receive(:class).and_return(ActiveRecord::Relation)
        allow(custom_relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        allow(custom_relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
        allow(custom_klass).to receive(:name).and_return('MyModel')
        allow(custom_klass).to receive(:where).with(id: [1, 2]).and_return(custom_relation)
        allow(custom_relation).to receive(:order).and_return(custom_relation)
        allow(custom_klass).to receive(:none).and_return(custom_relation)
        expected_hashes = custom_records.map { |r| { id: r.id, type: r.category } }
        expect(TypeBalancer).to receive(:balance) do |arg, type_field:|
          expect(arg).to all(include(:id, :type))
          expect(arg.map { |h| h[:type] }).to eq(custom_records.map(&:category))
          expect(type_field).to eq(:type)
          expected_hashes
        end
        custom_relation.balance_by_type(type_field: :category)
      end

      it 'delegates to TypeBalancer.balance with default type field' do
        relation = instance_double(ActiveRecord::Relation)
        klass = class_double('MyModel', name: 'MyModel')
        relation.extend(TypeBalancer::Rails::CollectionMethods)
        allow(relation).to receive(:to_a).and_return(records)
        allow(relation).to receive(:klass).and_return(klass)
        allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
        allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
        allow(klass).to receive(:name).and_return('MyModel')
        allow(klass).to receive(:where).with(id: [1, 2, 3]).and_return(relation)
        allow(relation).to receive(:order).and_return(relation)
        allow(klass).to receive(:none).and_return(relation)
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
        custom_relation = instance_double(ActiveRecord::Relation)
        custom_klass = class_double('MyModel', name: 'MyModel')
        custom_relation.extend(TypeBalancer::Rails::CollectionMethods)
        allow(custom_relation).to receive(:to_a).and_return(custom_records)
        allow(custom_relation).to receive(:klass).and_return(custom_klass)
        allow(custom_relation).to receive(:class).and_return(ActiveRecord::Relation)
        allow(custom_relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        allow(custom_relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
        allow(custom_klass).to receive(:name).and_return('MyModel')
        allow(custom_klass).to receive(:where).with(id: [1, 2, 3]).and_return(custom_relation)
        allow(custom_relation).to receive(:order).and_return(custom_relation)
        allow(custom_klass).to receive(:none).and_return(custom_relation)
        expected_hashes = custom_records.map { |r| { id: r.id, type: r.content_type } }
        expect(TypeBalancer).to receive(:balance) do |arg, type_field:|
          expect(arg).to all(include(:id, :type))
          expect(arg.map { |h| h[:type] }).to eq(custom_records.map(&:content_type))
          expect(type_field).to eq(:type)
          expected_hashes
        end
        custom_relation.balance_by_type(type_field: :content_type)
      end

      context 'with pagination' do
        let(:paginated_records) { records.first(2) }

        it 'preserves pagination' do
          relation = instance_double(ActiveRecord::Relation)
          klass = class_double('MyModel', name: 'MyModel')
          relation.extend(TypeBalancer::Rails::CollectionMethods)
          allow(relation).to receive(:to_a).and_return(records)
          allow(relation).to receive(:klass).and_return(klass)
          allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
          allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
          allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
          allow(klass).to receive(:name).and_return('MyModel')
          paginated_relation = instance_double(ActiveRecord::Relation)
          paginated_relation.extend(TypeBalancer::Rails::CollectionMethods)
          allow(relation).to receive(:limit).and_return(paginated_relation)
          allow(paginated_relation).to receive(:to_a).and_return(paginated_records)
          allow(paginated_relation).to receive(:klass).and_return(klass)
          allow(paginated_relation).to receive(:class).and_return(ActiveRecord::Relation)
          allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
          allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
          allow(klass).to receive(:name).and_return('MyModel')
          allow(klass).to receive(:where).with(id: [1, 2]).and_return(paginated_relation)
          allow(paginated_relation).to receive(:order).and_return(paginated_relation)
          allow(klass).to receive(:none).and_return(relation)
          expected_hashes = paginated_records.map { |r| { id: r.id, type: r.type } }
          expect(TypeBalancer).to receive(:balance) do |arg, type_field:|
            expect(arg).to all(include(:id, :type))
            expect(arg).to all(satisfy { |h| h.keys.sort == [:id, :type] })
            expect(type_field).to eq(:type)
            expected_hashes
          end
          paginated_relation.balance_by_type
        end
      end

      it 'returns records in the order of ids returned by the balancer (flat array)' do
        balanced_hashes = [
          { id: 2, type: 'Article' },
          { id: 1, type: 'Post' },
          { id: 3, type: 'Post' }
        ]
        records = [
          instance_double('MyModel', id: 1, type: 'Post', title: 'A', extra: 'foo'),
          instance_double('MyModel', id: 2, type: 'Article', title: 'B', extra: 'bar'),
          instance_double('MyModel', id: 3, type: 'Post', title: 'C', extra: 'baz')
        ]
        klass = class_double('MyModel', name: 'MyModel')
        ids = [2, 1, 3]
        ordered = [records[1], records[0], records[2]]
        relation = instance_double(ActiveRecord::Relation)
        relation.extend(TypeBalancer::Rails::CollectionMethods)
        allow(relation).to receive(:to_a).and_return(records)
        allow(relation).to receive(:klass).and_return(klass)
        allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
        allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
        allow(klass).to receive(:name).and_return('MyModel')
        allow(TypeBalancer).to receive(:balance).and_return(balanced_hashes)
        allow(klass).to receive(:where).with(id: ids).and_return(relation)
        allow(relation).to receive(:order).and_return(relation)
        allow(relation).to receive(:to_a).and_return(ordered)
        allow(klass).to receive(:none).and_return(relation)
        result = relation.balance_by_type
        expect(result.to_a).to eq(ordered)
      end

      it 'returns records in the order of ids returned by the balancer (nested array)' do
        balanced_hashes = [
          [{ id: 3, type: 'Post' }],
          [{ id: 1, type: 'Post' }, { id: 2, type: 'Article' }]
        ]
        records = [
          instance_double('MyModel', id: 1, type: 'Post', title: 'A', extra: 'foo'),
          instance_double('MyModel', id: 2, type: 'Article', title: 'B', extra: 'bar'),
          instance_double('MyModel', id: 3, type: 'Post', title: 'C', extra: 'baz')
        ]
        klass = class_double('MyModel', name: 'MyModel')
        ids = [3, 1, 2]
        ordered = [records[2], records[0], records[1]]
        relation = instance_double(ActiveRecord::Relation)
        relation.extend(TypeBalancer::Rails::CollectionMethods)
        allow(relation).to receive(:to_a).and_return(records)
        allow(relation).to receive(:klass).and_return(klass)
        allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
        allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
        allow(klass).to receive(:name).and_return('MyModel')
        allow(TypeBalancer).to receive(:balance).and_return(balanced_hashes)
        allow(klass).to receive(:where).with(id: ids).and_return(relation)
        allow(relation).to receive(:order).and_return(relation)
        allow(relation).to receive(:to_a).and_return(ordered)
        allow(klass).to receive(:none).and_return(relation)
        result = relation.balance_by_type
        expect(result.to_a).to eq(ordered)
      end

      it 'returns an ActiveRecord::Relation ordered by ids using a PostgreSQL CASE statement' do
        ar_model = Class.new do
          def self.where(conditions)
            @where_called = conditions
            self
          end

          def self.order(arg)
            @order_called = arg
            self
          end

          def self.to_a
            [OpenStruct.new(id: 2), OpenStruct.new(id: 1), OpenStruct.new(id: 3)]
          end

          def self.index_by
            { 2 => OpenStruct.new(id: 2), 1 => OpenStruct.new(id: 1), 3 => OpenStruct.new(id: 3) }
          end

          def self.called_where
            @where_called
          end

          def self.called_order
            @order_called
          end
        end
        relation = double('Relation', klass: ar_model,
                                      to_a: [OpenStruct.new(id: 1), OpenStruct.new(id: 2), OpenStruct.new(id: 3)])
        relation.extend(TypeBalancer::Rails::CollectionMethods)
        allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
        allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
        allow(TypeBalancer).to receive(:balance).and_return([
                                                              { id: 2, type: 'foo' },
                                                              { id: 1, type: 'bar' },
                                                              { id: 3, type: 'baz' }
                                                            ])
        result = relation.balance_by_type
        expect(ar_model.called_where).to eq({ id: [2, 1, 3] })
        expect(ar_model.called_order.to_s).to include('CASE id')
      end
    end
  end

  describe 'edge cases and coverage' do
    it 'returns empty relation if records are empty' do
      records = []
      relation = instance_double(ActiveRecord::Relation)
      klass = class_double('MyModel', name: 'MyModel')
      relation.extend(TypeBalancer::Rails::CollectionMethods)
      allow(relation).to receive(:to_a).and_return(records)
      allow(relation).to receive(:klass).and_return(klass)
      allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
      allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
      allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
      allow(klass).to receive(:name).and_return('MyModel')
      allow(klass).to receive(:where).with(id: []).and_return(relation)
      allow(relation).to receive(:order).and_return(relation)
      allow(klass).to receive(:none).and_return(relation)
      result = relation.balance_by_type
      expect(result.to_a).to be_empty
    end

    it 'returns empty relation if TypeBalancer.balance returns nil' do
      records = [instance_double('MyModel', id: 1, type: 'Post')]
      relation = instance_double(ActiveRecord::Relation)
      klass = class_double('MyModel', name: 'MyModel')
      relation.extend(TypeBalancer::Rails::CollectionMethods)
      allow(relation).to receive(:to_a).and_return(records)
      allow(relation).to receive(:klass).and_return(klass)
      allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
      allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
      allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
      allow(klass).to receive(:name).and_return('MyModel')
      allow(TypeBalancer).to receive(:balance).and_return(nil)
      empty_relation = instance_double(ActiveRecord::Relation)
      empty_relation.extend(TypeBalancer::Rails::CollectionMethods)
      allow(empty_relation).to receive(:to_a).and_return([])
      allow(empty_relation).to receive(:klass).and_return(klass)
      allow(empty_relation).to receive(:class).and_return(ActiveRecord::Relation)
      allow(empty_relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
      allow(empty_relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
      allow(empty_relation).to receive(:order).and_return(empty_relation)
      allow(klass).to receive(:none).and_return(empty_relation)
      allow(klass).to receive(:where).with(id: []).and_return(empty_relation)
      allow(empty_relation).to receive(:order).and_return(empty_relation)
      result = relation.balance_by_type
      expect(result.to_a).to be_empty
    end

    it 'returns all records if no pagination options are given' do
      records = [instance_double('MyModel', id: 1, type: 'post', title: 'First Post')]
      klass = class_double('MyModel', name: 'MyModel')
      ids = [1]
      relation = instance_double(ActiveRecord::Relation)
      relation.extend(TypeBalancer::Rails::CollectionMethods)
      allow(relation).to receive(:to_a).and_return(records)
      allow(relation).to receive(:klass).and_return(klass)
      allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
      allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
      allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
      allow(klass).to receive(:name).and_return('MyModel')
      allow(TypeBalancer).to receive(:balance).and_return(records.map { |r| { id: r.id, type: r.type } })
      allow(klass).to receive(:where).with(id: ids).and_return(relation)
      allow(relation).to receive(:order).and_return(relation)
      allow(relation).to receive(:to_a).and_return(records)
      allow(klass).to receive(:none).and_return(relation)
      result = relation.balance_by_type
      expect(result.to_a).to eq(records)
    end

    it 'returns paginated records if pagination options are given' do
      records = [
        instance_double('MyModel', id: 1, type: 'post', title: 'First Post'),
        instance_double('MyModel', id: 2, type: 'video', title: 'First Video')
      ]
      klass = class_double('MyModel', name: 'MyModel')
      ids = [2]
      paginated = [records[1]]
      relation = instance_double(ActiveRecord::Relation)
      relation.extend(TypeBalancer::Rails::CollectionMethods)
      allow(relation).to receive(:to_a).and_return(records)
      allow(relation).to receive(:klass).and_return(klass)
      allow(relation).to receive(:class).and_return(ActiveRecord::Relation)
      allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
      allow(relation).to receive(:kind_of?).with(ActiveRecord::Relation).and_return(true)
      allow(klass).to receive(:name).and_return('MyModel')
      allow(TypeBalancer).to receive(:balance).and_return(records.map { |r| { id: r.id, type: r.type } })
      allow(klass).to receive(:where).with(id: ids).and_return(relation)
      allow(relation).to receive(:order).and_return(relation)
      allow(relation).to receive(:to_a).and_return(paginated)
      allow(klass).to receive(:none).and_return(relation)
      result = relation.balance_by_type(page: 2, per_page: 1)
      expect(result.to_a).to eq([records[1]])
    end
  end
end
