# frozen_string_literal: true

require 'spec_helper'

module TypeBalancer
  module Rails
    module Query
      RSpec.describe PaginationService do
        let(:collection) { double('Collection').as_null_object }
        let(:options) { {} }
        let(:service) { described_class.new(collection, options) }

        before do
          allow(collection).to receive(:count).and_return(100)
          allow(collection).to receive(:respond_to?).and_return(false)
          allow(collection).to receive(:respond_to?).with(:offset).and_return(true)
          allow(collection).to receive(:respond_to?).with(:limit).and_return(true)
          allow(collection).to receive(:respond_to?).with(:count).and_return(true)
        end

        describe '#initialize' do
          it 'should use default values when no options provided' do
            expect(service.send(:page)).to eq(1)
            expect(service.send(:per_page)).to eq(25)
          end

          context 'with custom options' do
            let(:options) { { page: 2, per_page: 50 } }

            it 'should use provided values' do
              expect(service.send(:page)).to eq(2)
              expect(service.send(:per_page)).to eq(50)
            end
          end

          context 'with invalid values' do
            let(:options) { { page: 'invalid', per_page: 'invalid' } }

            it 'should convert to integers and use defaults if invalid' do
              expect(service.send(:page)).to eq(0)
              expect(service.send(:per_page)).to eq(25)
            end
          end

          context 'with per_page exceeding maximum' do
            let(:options) { { per_page: 200 } }

            it 'should cap at MAX_PER_PAGE' do
              expect(service.send(:per_page)).to eq(100)
            end
          end
        end

        describe '#paginate' do
          context 'when pagination is disabled' do
            let(:options) { { paginate: false } }

            it 'should return the original collection' do
              expect(service.paginate).to eq(collection)
            end
          end

          context 'with manual pagination' do
            before do
              allow(collection).to receive(:respond_to?).with(:page).and_return(false)
              allow(collection).to receive(:respond_to?).with(:paginate).and_return(false)
            end

            it 'should apply offset and limit' do
              expect(collection).to receive(:offset).with(0).ordered.and_return(collection)
              expect(collection).to receive(:limit).with(25).ordered.and_return(collection)
              service.paginate
            end

            context 'with custom page' do
              let(:options) { { page: 3, per_page: 10 } }

              it 'should calculate correct offset' do
                expect(collection).to receive(:offset).with(20).ordered.and_return(collection)
                expect(collection).to receive(:limit).with(10).ordered.and_return(collection)
                service.paginate
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

            it 'should use Kaminari pagination' do
              expect(collection).to receive(:page).with(1).and_return(kaminari_collection)
              expect(kaminari_collection).to receive(:per).with(25)
              service.paginate
            end
          end

          context 'with WillPaginate' do
            before do
              stub_const('WillPaginate::Collection', Class.new)
              allow(collection).to receive(:respond_to?).with(:page).and_return(false)
              allow(collection).to receive(:respond_to?).with(:paginate).and_return(true)
            end

            it 'should use WillPaginate pagination' do
              expect(collection).to receive(:paginate).with(page: 1, per_page: 25)
              service.paginate
            end
          end

          context 'with ActiveRecord collection' do
            let(:collection) do
              double('ActiveRecord::Relation').tap do |double|
                allow(double).to receive(:respond_to?).with(:page).and_return(false)
                allow(double).to receive(:respond_to?).with(:paginate).and_return(false)
                allow(double).to receive(:offset).and_return(double)
                allow(double).to receive(:limit).and_return(double)
                allow(double).to receive(:count).and_return(100)
              end
            end

            it 'should apply offset and limit correctly' do
              expect(collection).to receive(:offset).with(0).ordered.and_return(collection)
              expect(collection).to receive(:limit).with(25).ordered.and_return(collection)
              service.paginate
            end

            it 'should cache the total count' do
              expect(collection).to receive(:count).once.and_return(100)
              2.times { service.total_pages }
            end
          end

          context 'with negative page number' do
            let(:options) { { page: -1 } }

            it 'should default to page 1' do
              expect(collection).to receive(:offset).with(0).ordered.and_return(collection)
              expect(collection).to receive(:limit).with(25).ordered.and_return(collection)
              service.paginate
            end
          end

          context 'with zero per_page' do
            let(:options) { { per_page: 0 } }

            it 'should use default per_page' do
              expect(collection).to receive(:offset).with(0).ordered.and_return(collection)
              expect(collection).to receive(:limit).with(25).ordered.and_return(collection)
              service.paginate
            end
          end
        end

        describe '#next_page?' do
          context 'when there are more pages' do
            before { allow(collection).to receive(:count).and_return(30) }

            it 'should return true' do
              expect(service.next_page?).to be true
            end
          end

          context 'when on the last page' do
            before { allow(collection).to receive(:count).and_return(20) }

            it 'should return false' do
              expect(service.next_page?).to be false
            end
          end
        end

        describe '#prev_page?' do
          context 'on first page' do
            let(:options) { { page: 1 } }

            it 'should return false' do
              expect(service.prev_page?).to be false
            end
          end

          context 'on subsequent pages' do
            let(:options) { { page: 2 } }

            it 'should return true' do
              expect(service.prev_page?).to be true
            end
          end
        end

        describe '#total_pages' do
          context 'with exact division' do
            before { allow(collection).to receive(:count).and_return(50) }

            it 'should calculate correct number of pages' do
              expect(service.total_pages).to eq(2)
            end
          end

          context 'with remainder' do
            before { allow(collection).to receive(:count).and_return(55) }

            it 'should round up to include partial page' do
              expect(service.total_pages).to eq(3)
            end
          end

          context 'with empty collection' do
            before { allow(collection).to receive(:count).and_return(0) }

            it 'should return zero' do
              expect(service.total_pages).to eq(0)
            end
          end
        end

        describe '#current_page' do
          let(:options) { { page: 3 } }

          it 'should return the current page number' do
            expect(service.current_page).to eq(3)
          end
        end

        describe '#total_count' do
          it 'should cache the count result' do
            expect(collection).to receive(:count).once.and_return(100)
            2.times { service.send(:total_count) }
          end

          context 'when count returns nil' do
            before { allow(collection).to receive(:count).and_return(nil) }

            it 'should handle nil count gracefully' do
              expect(service.total_pages).to eq(0)
            end
          end
        end

        describe 'error handling' do
          context 'when collection does not respond to required methods' do
            before do
              allow(collection).to receive(:respond_to?).with(:offset).and_return(false)
            end

            it 'should raise an informative error' do
              expect { service.paginate }.to raise_error(NoMethodError)
            end
          end
        end
      end
    end
  end
end 