require 'spec_helper'
require 'type_balancer/rails/cache_adapter'

describe TypeBalancer::Rails::CacheAdapter do
  let(:adapter) { described_class.new }

  describe '#clear_cache!' do
    context 'when Rails.cache is defined' do
      let(:rails_cache) { double('Rails.cache') }

      before do
        stub_const('Rails', Class.new)
        allow(Rails).to receive(:respond_to?) do |*args|
          [[:cache], [:cache, true]].include?(args)
        end
        allow(Rails).to receive(:cache).and_return(rails_cache)
        allow(rails_cache).to receive(:clear)
        adapter.instance_variable_set(:@memory_cache, { foo: 'bar' })
      end

      it 'clears Rails.cache and in-memory cache' do
        expect(rails_cache).to receive(:clear)
        adapter.clear_cache!
        expect(adapter.instance_variable_get(:@memory_cache)).to be_empty
      end
    end

    context 'when Rails.cache is not defined' do
      before do
        adapter.instance_variable_set(:@memory_cache, { foo: 'bar' })
      end

      it 'clears only in-memory cache' do
        adapter.clear_cache!
        expect(adapter.instance_variable_get(:@memory_cache)).to be_empty
      end
    end
  end
end
