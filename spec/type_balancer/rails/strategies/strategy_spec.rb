# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Strategies::Strategy do
  let(:collection_query) { instance_double(TypeBalancer::Rails::Query::BalancedQuery) }
  let(:strategy) { described_class.new(collection_query) }

  describe '#initialize' do
    context 'when collection_query is nil' do
      it 'raises ArgumentError' do
        expect { described_class.new(nil) }.to raise_error(ArgumentError)
      end
    end

    context 'when collection_query is valid' do
      it 'initializes without error' do
        expect { described_class.new(collection_query) }.not_to raise_error
      end
    end
  end

  describe '#execute' do
    it 'raises NotImplementedError' do
      expect { strategy.execute }.to raise_error(NotImplementedError)
    end
  end

  describe 'method visibility' do
    it 'has protected access to collection_query' do
      expect(described_class.protected_instance_methods).to include(:collection_query)
    end

    it 'does not expose collection_query publicly' do
      expect(described_class.public_instance_methods(false)).not_to include(:collection_query)
    end
  end
end
