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

        describe '#initialize' do
          it 'uses default values when no options provided' do
            expect(service.send(:page)).to eq(1)
            expect(service.send(:per_page)).to eq(25)
          end

          context 'with custom options' do
            let(:options) { { page: 2, per_page: 50 } }

            it 'uses provided values' do
              expect(service.send(:page)).to eq(2)
              expect(service.send(:per_page)).to eq(50)
            end
          end

          context 'with invalid values' do
            let(:options) { { page: 'invalid', per_page: 'invalid' } }

            it 'converts to integers and use defaults if invalid' do
              expect(service.send(:page)).to eq(0)
              expect(service.send(:per_page)).to eq(25)
            end
          end

          context 'with per_page exceeding maximum' do
            let(:options) { { per_page: 200 } }

            it 'caps at MAX_PER_PAGE' do
              expect(service.send(:per_page)).to eq(100)
            end
          end
        end
      end
    end
  end
end
