# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Query::PaginationService do
  let(:model_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'posts'
    end
  end

  let(:collection) { model_class.all }
  let(:options) { {} }

  subject(:service) { described_class.new(collection, options) }

  before do
    allow(collection).to receive(:count).and_return(100)
    allow(collection).to receive(:offset).and_return(collection)
    allow(collection).to receive(:limit).and_return(collection)
  end

  describe '#initialize' do
    it 'sets default page and per_page values' do
      expect(service.current_page).to eq(1)
      expect(service.send(:per_page)).to eq(25)
    end

    context 'with custom options' do
      let(:options) { { page: 2, per_page: 30 } }

      it 'uses provided values' do
        expect(service.current_page).to eq(2)
        expect(service.send(:per_page)).to eq(30)
      end
    end

    context 'with per_page exceeding maximum' do
      let(:options) { { per_page: 200 } }

      it 'caps per_page at maximum value' do
        expect(service.send(:per_page)).to eq(100)
      end
    end
  end

  describe '#paginate' do
    context 'when pagination is disabled' do
      let(:options) { { paginate: false } }

      it 'returns the original collection' do
        expect(service.paginate).to eq(collection)
      end
    end

    context 'with manual pagination' do
      it 'applies offset and limit' do
        expect(collection).to receive(:offset).with(0)
        expect(collection).to receive(:limit).with(25)
        service.paginate
      end

      context 'on page 2' do
        let(:options) { { page: 2 } }

        it 'calculates correct offset' do
          expect(collection).to receive(:offset).with(25)
          service.paginate
        end
      end
    end

    context 'with Kaminari' do
      before do
        stub_const('Kaminari', Module.new)
        allow(collection).to receive(:page).and_return(collection)
        allow(collection).to receive(:per).and_return(collection)
      end

      it 'uses Kaminari pagination' do
        expect(collection).to receive(:page).with(1)
        expect(collection).to receive(:per).with(25)
        service.paginate
      end
    end

    context 'with WillPaginate' do
      before do
        stub_const('WillPaginate::Collection', Class.new)
        allow(collection).to receive(:paginate).and_return(collection)
      end

      it 'uses WillPaginate pagination' do
        expect(collection).to receive(:paginate).with(page: 1, per_page: 25)
        service.paginate
      end
    end
  end

  describe '#next_page?' do
    context 'when there are more records' do
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

  describe '#prev_page?' do
    context 'on first page' do
      it 'returns false' do
        expect(service.prev_page?).to be false
      end
    end

    context 'on subsequent pages' do
      let(:options) { { page: 2 } }

      it 'returns true' do
        expect(service.prev_page?).to be true
      end
    end
  end

  describe '#total_pages' do
    before { allow(collection).to receive(:count).and_return(55) }

    it 'calculates total pages' do
      expect(service.total_pages).to eq(3)
    end

    context 'with custom per_page' do
      let(:options) { { per_page: 10 } }

      it 'adjusts total pages calculation' do
        expect(service.total_pages).to eq(6)
      end
    end
  end
end 