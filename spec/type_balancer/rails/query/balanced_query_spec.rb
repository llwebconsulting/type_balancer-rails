# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Query::BalancedQuery do
  let(:model_class) do
    class_double(ActiveRecord::Base).tap do |double|
      allow(double).to receive(:column_names).and_return(['id', 'model_type'])
    end
  end

  let(:scope) do
    instance_double(ActiveRecord::Relation).tap do |double|
      allow(double).to receive(:is_a?).with(any_args).and_return(false)
      allow(double).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
      allow(double).to receive_messages(klass: model_class, where: double, order: double)
    end
  end

  let(:query_builder) do
    instance_double(TypeBalancer::Rails::Query::QueryBuilder).tap do |double|
      allow(double).to receive_messages(scope: scope, apply_order: scope, apply_conditions: scope)
    end
  end

  let(:type_field_resolver) do
    instance_double(TypeBalancer::Rails::Query::TypeFieldResolver).tap do |double|
      allow(double).to receive(:resolve).with('model_type').and_return('model_type')
      allow(double).to receive(:resolve).with(nil).and_return(nil)
    end
  end

  let(:options) { { order: :created_at, conditions: { active: true }, type_field: 'model_type' } }

  before do
    allow(TypeBalancer::Rails::Query::QueryBuilder).to receive(:new).and_return(query_builder)
    allow(TypeBalancer::Rails::Query::TypeFieldResolver).to receive(:new).and_return(type_field_resolver)
  end

  describe '#initialize' do
    it 'sets up the query builder and type field resolver' do
      described_class.new(scope, options)
      expect(TypeBalancer::Rails::Query::QueryBuilder).to have_received(:new)
      expect(TypeBalancer::Rails::Query::TypeFieldResolver).to have_received(:new)
    end

    context 'when scope is a hash with :collection key' do
      let(:collection_scope) { scope }
      let(:hash_scope) do
        { collection: collection_scope }.tap do |hash|
          allow(hash).to receive(:is_a?).with(any_args).and_return(false)
          allow(hash).to receive(:is_a?).with(Hash).and_return(true)
        end
      end

      it 'extracts the scope from the hash' do
        described_class.new(hash_scope, options)
        expect(TypeBalancer::Rails::Query::QueryBuilder).to have_received(:new)
      end
    end
  end

  describe '#build' do
    subject(:query) { described_class.new(scope, options) }

    it 'builds the query using the components' do
      result = query.build
      expect(result).to eq(scope)
      expect(query_builder).to have_received(:apply_order)
      expect(query_builder).to have_received(:apply_conditions)
      expect(type_field_resolver).to have_received(:resolve).with('model_type')
    end

    context 'when no type field is provided' do
      let(:options) { { order: :created_at, conditions: { active: true } } }

      it 'raises an error if no type field can be resolved' do
        expect do
          query.build
        end.to raise_error(ArgumentError, 'No type field found. Please specify one using type_field: :your_field')
      end
    end

    context 'when type field can be inferred' do
      let(:options) { { order: :created_at, conditions: { active: true } } }

      before do
        allow(type_field_resolver).to receive(:resolve).with(nil).and_return('inferred_type')
      end

      it 'uses the inferred type field' do
        result = query.build
        expect(result).to eq(scope)
        expect(type_field_resolver).to have_received(:resolve).with(nil)
      end
    end
  end

  describe '#with_options' do
    subject(:query) { described_class.new(scope, options) }

    it 'returns a new instance with merged options' do
      new_options = { conditions: { status: 'active' } }
      new_query = query.with_options(new_options)

      expect(new_query).to be_a(described_class)
      expect(new_query.options).to eq(options.merge(new_options))
    end
  end
end
