# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Query do
  # Following our testing strategy:
  # 1. Only mock components that are already tested
  # 2. Test only what this module is responsible for
  # 3. Use proper ActiveRecord test doubles

  let(:scope) { instance_double(ActiveRecord::Relation) }
  let(:options) { { order: :created_at, conditions: { active: true } } }

  let(:balanced_query) do
    instance_double(TypeBalancer::Rails::Query::BalancedQuery).tap do |double|
      allow(double).to receive(:build).and_return(scope)
    end
  end

  describe '.build' do
    before do
      # Allow BalancedQuery.new to be called with any arguments
      allow(TypeBalancer::Rails::Query::BalancedQuery)
        .to receive(:new)
        .with(any_args)
        .and_return(balanced_query)
    end

    it 'creates a new BalancedQuery with the given scope and options' do
      described_class.build(scope, options)
      expect(TypeBalancer::Rails::Query::BalancedQuery)
        .to have_received(:new)
        .with(scope, options)
    end

    it 'delegates query building to BalancedQuery' do
      result = described_class.build(scope, options)
      expect(balanced_query).to have_received(:build)
      expect(result).to eq(scope)
    end

    context 'when no options are provided' do
      it 'uses an empty hash as default options' do
        described_class.build(scope)
        expect(TypeBalancer::Rails::Query::BalancedQuery)
          .to have_received(:new)
          .with(scope, {})
      end
    end

    context 'when scope is nil' do
      let(:scope) { nil }

      it 'still passes the nil scope to BalancedQuery' do
        described_class.build(scope, options)
        expect(TypeBalancer::Rails::Query::BalancedQuery)
          .to have_received(:new)
          .with(nil, options)
      end
    end
  end
end
