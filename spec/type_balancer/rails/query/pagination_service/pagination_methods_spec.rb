# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/query/pagination_service'

module TypeBalancer
  module Rails
    module Query
      RSpec.describe PaginationService do
        let(:collection) { double('Collection').as_null_object }
        let(:options) { {} }
        let(:service) { described_class.new(collection, options) }

        before do
          allow(collection).to receive_messages(count: 100, respond_to?: false)
          allow(collection).to receive(:respond_to?).with(:offset).and_return(true)
          allow(collection).to receive(:respond_to?).with(:limit).and_return(true)
          allow(collection).to receive(:respond_to?).with(:count).and_return(true)
        end

        describe '#paginate' do
          context 'when pagination is disabled' do
            let(:options) { { paginate: false } }

            it 'returns the original collection' do
              expect(service.paginate).to eq(collection)
            end
          end

          context 'with manual pagination' do
            before do
              allow(collection).to receive(:respond_to?).with(:page).and_return(false)
              allow(collection).to receive(:respond_to?).with(:paginate).and_return(false)
            end

            it 'applies offset and limit' do
              allow(collection).to receive_messages(offset: collection, limit: collection)
              service.paginate
              expect(collection).to have_received(:offset).with(0)
              expect(collection).to have_received(:limit).with(25)
            end

            context 'with custom page' do
              let(:options) { { page: 3, per_page: 10 } }

              it 'calculates correct offset' do
                allow(collection).to receive_messages(offset: collection, limit: collection)
                service.paginate
                expect(collection).to have_received(:offset).with(20)
                expect(collection).to have_received(:limit).with(10)
              end
            end
          end

          context 'with Kaminari' do
            let(:kaminari_collection) { double('KaminariCollection') }

            before do
              stub_const('Kaminari', Module.new)
              allow(collection).to receive(:respond_to?).with(:page).and_return(true)
              allow(collection).to receive(:respond_to?).with(:paginate).and_return(false)
              allow(kaminari_collection).to receive(:per).and_return(kaminari_collection)
            end

            it 'uses Kaminari pagination' do
              allow(collection).to receive(:page).with(1).and_return(kaminari_collection)
              allow(kaminari_collection).to receive(:per).with(25)
              service.paginate
              expect(collection).to have_received(:page).with(1)
              expect(kaminari_collection).to have_received(:per).with(25)
            end
          end

          context 'with WillPaginate' do
            before do
              stub_const('WillPaginate::Collection', Class.new)
              allow(collection).to receive(:respond_to?).with(:page).and_return(false)
              allow(collection).to receive(:respond_to?).with(:paginate).and_return(true)
            end

            it 'uses WillPaginate pagination' do
              allow(collection).to receive(:paginate).with(page: 1, per_page: 25)
              service.paginate
              expect(collection).to have_received(:paginate).with(page: 1, per_page: 25)
            end
          end

          context 'with ActiveRecord collection' do
            let(:collection) do
              double('ActiveRecord::Relation').tap do |double|
                allow(double).to receive(:respond_to?).with(:page).and_return(false)
                allow(double).to receive(:respond_to?).with(:paginate).and_return(false)
                allow(double).to receive_messages(offset: double, limit: double, count: 100)
              end
            end

            it 'applies offset and limit correctly' do
              allow(collection).to receive_messages(offset: collection, limit: collection)
              service.paginate
              expect(collection).to have_received(:offset).with(0)
              expect(collection).to have_received(:limit).with(25)
            end

            it 'caches the total count' do
              allow(collection).to receive(:count).once.and_return(100)
              2.times { service.total_pages }
              expect(collection).to have_received(:count).once
            end
          end

          context 'with negative page number' do
            let(:options) { { page: -1 } }

            it 'defaults to page 1' do
              allow(collection).to receive_messages(offset: collection, limit: collection)
              service.paginate
              expect(collection).to have_received(:offset).with(0)
              expect(collection).to have_received(:limit).with(25)
            end
          end

          context 'with zero per_page' do
            let(:options) { { per_page: 0 } }

            it 'uses default per_page' do
              allow(collection).to receive_messages(offset: collection, limit: collection)
              service.paginate
              expect(collection).to have_received(:offset).with(0)
              expect(collection).to have_received(:limit).with(25)
            end
          end
        end

        describe '#next_page?' do
          context 'when there are more pages' do
            before { allow(collection).to receive(:count).and_return(30) }

            it 'returns true' do
              expect(service.next_page?).to be true
            end
          end

          context 'when on the last page' do
            before { allow(collection).to receive(:count).and_return(20) }

            it 'returns false' do
              expect(service.next_page?).to be false
            end
          end
        end
      end
    end
  end
end
