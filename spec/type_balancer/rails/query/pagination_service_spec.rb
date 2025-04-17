# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/query/pagination_service'

module TypeBalancer
  module Rails
    module Query
      RSpec.describe PaginationService do
        let(:collection) { double('Collection').as_null_object }
        let(:cursor_strategy) { instance_double(TypeBalancer::Rails::Strategies::CursorStrategy) }
        let(:cursor_service) { instance_double(TypeBalancer::Rails::Query::CursorService) }
        let(:page) { 1 }
        let(:per_page) { 25 }
        let(:paginated_scope) { double('PaginatedScope') }
        let(:total_count) { 100 }
        let(:next_page) { 2 }
        let(:prev_page) { nil }
        let(:scope) { collection }
        let(:options) { { cursor_strategy: cursor_strategy } }
        let(:service) { described_class.new(collection, options) }

        before do
          allow(collection).to receive_messages(count: 100, respond_to?: false)
          allow(collection).to receive(:respond_to?).with(:offset).and_return(true)
          allow(collection).to receive(:respond_to?).with(:limit).and_return(true)
          allow(collection).to receive(:respond_to?).with(:count).and_return(true)
        end

        describe '#paginate with cursor strategy' do
          before do
            allow(TypeBalancer::Rails::Strategies::CursorStrategy).to receive(:new).and_return(cursor_strategy)
            allow(TypeBalancer::Rails::Query::CursorService)
              .to receive(:new)
              .with(scope, strategy: cursor_strategy)
              .and_return(cursor_service)
            allow(cursor_service).to receive_messages(
              total_count: total_count,
              next_page: next_page,
              prev_page: prev_page
            )
            allow(cursor_service).to receive(:paginate).with(page: page,
                                                             per_page: per_page).and_return(paginated_scope)
          end

          it 'returns paginated data with metadata' do
            result = service.paginate

            expect(result).to eq({
                                   data: paginated_scope,
                                   metadata: {
                                     total_count: total_count,
                                     next_page: next_page,
                                     prev_page: prev_page,
                                     current_page: page,
                                     per_page: per_page
                                   }
                                 })
          end

          context 'when storage error occurs' do
            before do
              allow(cursor_service).to receive(:paginate).and_raise(RuntimeError, 'Storage error')
            end

            it 'raises PaginationError' do
              expect do
                service.paginate
              end.to raise_error(TypeBalancer::Rails::Errors::PaginationError, 'Storage error')
            end
          end

          context 'when position calculation error occurs' do
            before do
              allow(cursor_service).to receive(:paginate).and_raise(RuntimeError, 'Position calculation error')
            end

            it 'raises PaginationError' do
              expect do
                service.paginate
              end.to raise_error(TypeBalancer::Rails::Errors::PaginationError, 'Position calculation error')
            end
          end
        end
      end
    end
  end
end
