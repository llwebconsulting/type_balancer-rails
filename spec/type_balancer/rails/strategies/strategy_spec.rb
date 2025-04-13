# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Strategies::Strategy do
  let(:collection_query) { instance_double('TypeBalancer::Rails::Query::CollectionQuery') }
  let(:strategy) { described_class.new(collection_query) }

  describe '#initialize' do
    context 'when given a valid collection query' do
      it 'should store the collection query as a protected attribute' do
        test_strategy = Class.new(described_class) do
          def get_collection_query
            collection_query
          end
        end
        instance = test_strategy.new(collection_query)
        expect(instance.get_collection_query).to eq(collection_query)
      end
    end

    context 'when given nil' do
      it 'should raise ArgumentError' do
        expect { described_class.new(nil) }.to raise_error(
          ArgumentError,
          'collection_query is required'
        )
      end
    end
  end

  describe '#execute' do
    it 'should raise NotImplementedError with implementation instructions' do
      expect { strategy.execute }.to raise_error(
        NotImplementedError,
        "#{described_class} must implement #execute"
      )
    end
  end

  describe 'method visibility' do
    it 'should have protected access to collection_query' do
      expect(described_class.protected_instance_methods).to include(:collection_query)
    end

    it 'should not expose collection_query publicly' do
      expect(described_class.public_instance_methods(false)).not_to include(:collection_query)
    end
  end
end 