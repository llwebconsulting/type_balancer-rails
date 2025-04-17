# frozen_string_literal: true

require 'spec_helper'

module TypeBalancer
  module Rails
    module Query
      RSpec.describe QueryBuilder do
        let(:scope) do
          instance_double(ActiveRecord::Relation).tap do |double|
            allow(double).to receive_messages(where: double, order: double)
          end
        end
        let(:builder) { described_class.new(scope) }

        describe '#initialize' do
          it 'stores the scope' do
            expect(builder.scope).to eq(scope)
          end
        end

        describe '#apply_order' do
          context 'with no order specified' do
            it 'returns the original scope' do
              expect(builder.apply_order(nil)).to eq(scope)
              expect(scope).not_to have_received(:order)
            end
          end

          context 'with symbol order' do
            it 'applies the order clause as string' do
              builder.apply_order(:created_at)
              expect(scope).to have_received(:order).with('created_at')
            end
          end

          context 'with string order' do
            it 'applies the order clause as is' do
              builder.apply_order('created_at')
              expect(scope).to have_received(:order).with('created_at')
            end
          end

          context 'with array order' do
            it 'applies multiple order clauses as strings' do
              builder.apply_order([:created_at, :updated_at])
              expect(scope).to have_received(:order).with(['created_at', 'updated_at'])
            end
          end

          context 'with hash order' do
            it 'applies hash order with string values but keeps symbol keys' do
              builder.apply_order({ created_at: :desc })
              expect(scope).to have_received(:order).with({ created_at: 'desc' })
            end
          end

          context 'with invalid order format' do
            it 'raises ArgumentError' do
              expect { builder.apply_order(Object.new) }
                .to raise_error(ArgumentError, 'Invalid order format')
            end
          end
        end

        describe '#apply_conditions' do
          context 'with no conditions' do
            it 'returns the original scope for nil' do
              expect(builder.apply_conditions(nil)).to eq(scope)
              expect(scope).not_to have_received(:where)
            end

            it 'returns the original scope for empty hash' do
              expect(builder.apply_conditions({})).to eq(scope)
              expect(scope).not_to have_received(:where)
            end
          end

          context 'with conditions' do
            let(:conditions) { { status: 'active', category: 'blog' } }

            it 'applies the conditions to the scope' do
              builder.apply_conditions(conditions)
              expect(scope).to have_received(:where).with(conditions)
            end
          end
        end
      end
    end
  end
end
