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

  let(:test_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'posts'
      include TypeBalancer::Rails::Pagination
    end
  end

  let(:position_manager) { instance_double(TypeBalancer::Rails::Query::PositionManager) }

  before do
    allow(TypeBalancer::Rails::Query::PositionManager).to receive(:new)
      .with(test_class)
      .and_return(position_manager)
    allow(position_manager).to receive(:calculate_positions)
      .and_return(positions)
  end

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

  describe '.paginate scope' do
    context 'with default parameters' do
      it 'uses default page and per_page values' do
        expect(test_class).to receive(:where).with(id: [1, 2, 3, 4, 5])
                                             .and_return(test_class)
        expect(test_class).to receive(:reorder)
          .with(Arel.sql('FIELD(id, 1,2,3,4,5)'))
          .and_return(test_class)

        test_class.paginate
      end
    end

    context 'with custom page and per_page' do
      it 'paginates correctly' do
        expect(test_class).to receive(:where).with(id: [3, 4])
                                             .and_return(test_class)
        expect(test_class).to receive(:reorder)
          .with(Arel.sql('FIELD(id, 3,4)'))
          .and_return(test_class)

        test_class.paginate(page: 2, per_page: 2)
      end
    end

    context 'when per_page exceeds MAX_PER_PAGE' do
      it 'caps per_page at MAX_PER_PAGE' do
        expect(test_class).to receive(:where).with(id: [1, 2, 3, 4, 5])
                                             .and_return(test_class)
        expect(test_class).to receive(:reorder)
          .with(Arel.sql('FIELD(id, 1,2,3,4,5)'))
          .and_return(test_class)

        test_class.paginate(per_page: TypeBalancer::Rails::Pagination::MAX_PER_PAGE + 100)
      end
    end

    context 'with invalid page number' do
      it 'uses page 1 for negative numbers' do
        expect(test_class).to receive(:where).with(id: [1, 2, 3, 4, 5])
                                             .and_return(test_class)
        expect(test_class).to receive(:reorder)
          .with(Arel.sql('FIELD(id, 1,2,3,4,5)'))
          .and_return(test_class)

        test_class.paginate(page: -1)
      end
    end

    context 'with empty positions' do
      before do
        allow(position_manager).to receive(:calculate_positions).and_return({})
      end

      it 'returns none relation' do
        expect(test_class).to receive(:none).and_return(test_class)
        test_class.paginate
      end
    end

    context 'when offset exceeds available records' do
      it 'returns none relation' do
        expect(test_class).to receive(:none).and_return(test_class)
        test_class.paginate(page: 100)
      end
    end
  end
end
