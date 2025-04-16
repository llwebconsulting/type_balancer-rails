# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Pagination do
  let(:per_page) { 10 }
  let(:page) { 1 }
  let(:pagination) { described_class.new(per_page: per_page, page: page) }
  let(:relation) { instance_double(ActiveRecord::Relation) }
  let(:where_relation) { instance_double(ActiveRecord::Relation) }
  let(:none_relation) { instance_double(ActiveRecord::Relation) }
  let(:reorder_relation) { instance_double(ActiveRecord::Relation) }
  let(:positions) { { 1 => 1.0, 2 => 2.0, 3 => 3.0, 4 => 4.0, 5 => 5.0 } }

  describe '#initialize' do
    context 'with default values' do
      subject(:pagination) { described_class.new }

      it 'uses default per_page' do
        expect(pagination.instance_variable_get(:@per_page)).to eq(described_class::DEFAULT_PER_PAGE)
      end

      it 'uses default page' do
        expect(pagination.instance_variable_get(:@page)).to eq(1)
      end
    end

    context 'with custom values' do
      it 'sets custom per_page' do
        expect(pagination.instance_variable_get(:@per_page)).to eq(per_page)
      end

      it 'sets custom page' do
        expect(pagination.instance_variable_get(:@page)).to eq(page)
      end
    end

    context 'when per_page exceeds MAX_PER_PAGE' do
      let(:per_page) { described_class::MAX_PER_PAGE + 10 }

      it 'caps per_page at MAX_PER_PAGE' do
        expect(pagination.instance_variable_get(:@per_page)).to eq(described_class::MAX_PER_PAGE)
      end
    end
  end

  describe '#apply_to' do
    context 'with empty positions' do
      let(:positions) { [] }
      let(:pagination) { described_class.new(positions, page: 1, per_page: 2) }

      it 'returns none relation' do
        allow(relation).to receive(:none).and_return(none_relation)
        expect(pagination.apply_to(relation)).to eq(none_relation)
      end
    end

    context 'with valid positions' do
      let(:positions) { [{ id: 1, position: 0.5 }] }
      let(:pagination) { described_class.new(positions, page: 1, per_page: 2) }

      it 'applies where and reorder' do
        allow(relation).to receive(:where).with(id: [1]).and_return(where_relation)
        allow(where_relation).to receive(:reorder).with(Arel.sql('FIELD(id, 1)')).and_return(reorder_relation)

        expect(pagination.apply_to(relation)).to eq(reorder_relation)
      end
    end

    context 'with multiple positions' do
      let(:positions) do
        [
          { id: 1, position: 0.1 },
          { id: 2, position: 0.2 },
          { id: 3, position: 0.3 }
        ]
      end

      context 'when on first page' do
        let(:pagination) { described_class.new(positions, page: 1, per_page: 2) }

        it 'selects first slice of positions' do
          allow(relation).to receive(:where).with(id: [1, 2]).and_return(where_relation)
          allow(where_relation).to receive(:reorder).with(Arel.sql('FIELD(id, 1,2)')).and_return(reorder_relation)

          expect(pagination.apply_to(relation)).to eq(reorder_relation)
        end
      end

      context 'when on second page' do
        let(:pagination) { described_class.new(positions, page: 2, per_page: 2) }

        it 'selects second slice of positions' do
          allow(relation).to receive(:where).with(id: [3]).and_return(where_relation)
          allow(where_relation).to receive(:reorder).with(Arel.sql('FIELD(id, 3)')).and_return(reorder_relation)

          expect(pagination.apply_to(relation)).to eq(reorder_relation)
        end
      end
    end
  end

  describe 'private methods' do
    describe '#page_offset' do
      context 'when on first page' do
        let(:page) { 1 }

        it 'returns 0' do
          expect(pagination.send(:page_offset)).to eq(0)
        end
      end

      context 'when on subsequent pages' do
        let(:page) { 3 }
        let(:per_page) { 5 }

        it 'calculates correct offset' do
          expect(pagination.send(:page_offset)).to eq(10)
        end
      end
    end

    describe '#position_order_clause' do
      it 'generates correct SQL fragment' do
        record_ids = [1, 2, 3]
        sql = pagination.send(:position_order_clause, record_ids)
        expect(sql.to_s).to eq('FIELD(id, 1,2,3)')
      end
    end
  end
end
