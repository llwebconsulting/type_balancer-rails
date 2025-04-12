# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Storage::CacheDecorator do
  let(:storage) { instance_double('TypeBalancer::Rails::Storage::BaseStorage') }
  let(:cache_store) { instance_double('ActiveSupport::Cache::Store') }
  let(:configuration) { instance_double('TypeBalancer::Rails::Configuration', cache_enabled: true) }

  before do
    allow(Rails).to receive(:cache).and_return(cache_store)
    allow(TypeBalancer::Rails).to receive(:configuration).and_return(configuration)
  end

  subject(:decorator) { described_class.new(storage) }

  describe '#store' do
    let(:key) { 'test_key' }
    let(:value) { 'test_value' }
    let(:ttl) { 3600 }

    before do
      allow(storage).to receive(:store).with(key, value, ttl)
      allow(cache_store).to receive(:write)
    end

    it 'delegates to storage' do
      decorator.store(key, value, ttl)
      expect(storage).to have_received(:store).with(key, value, ttl)
    end

    context 'when caching is enabled' do
      it 'writes to cache' do
        decorator.store(key, value, ttl)
        expect(cache_store).to have_received(:write)
          .with("type_balancer/base_storage/#{key}", value, expires_in: ttl)
      end
    end

    context 'when caching is disabled' do
      let(:configuration) { instance_double('TypeBalancer::Rails::Configuration', cache_enabled: false) }

      it 'does not write to cache' do
        decorator.store(key, value, ttl)
        expect(cache_store).not_to have_received(:write)
      end
    end
  end

  describe '#fetch' do
    let(:key) { 'test_key' }
    let(:value) { 'test_value' }

    before do
      allow(storage).to receive(:fetch).with(key).and_return(value)
      allow(cache_store).to receive(:fetch).and_yield
    end

    it 'delegates to storage when cache misses' do
      decorator.fetch(key)
      expect(storage).to have_received(:fetch).with(key)
    end

    context 'when caching is enabled' do
      it 'uses cache' do
        decorator.fetch(key)
        expect(cache_store).to have_received(:fetch)
          .with("type_balancer/base_storage/#{key}")
      end
    end

    context 'when caching is disabled' do
      let(:configuration) { instance_double('TypeBalancer::Rails::Configuration', cache_enabled: false) }

      it 'bypasses cache' do
        decorator.fetch(key)
        expect(cache_store).not_to have_received(:fetch)
      end
    end
  end

  describe '#delete' do
    let(:key) { 'test_key' }

    before do
      allow(storage).to receive(:delete).with(key)
      allow(cache_store).to receive(:delete)
    end

    it 'delegates to storage' do
      decorator.delete(key)
      expect(storage).to have_received(:delete).with(key)
    end

    context 'when caching is enabled' do
      it 'deletes from cache' do
        decorator.delete(key)
        expect(cache_store).to have_received(:delete)
          .with("type_balancer/base_storage/#{key}")
      end
    end

    context 'when caching is disabled' do
      let(:configuration) { instance_double('TypeBalancer::Rails::Configuration', cache_enabled: false) }

      it 'does not delete from cache' do
        decorator.delete(key)
        expect(cache_store).not_to have_received(:delete)
      end
    end
  end

  describe '#clear' do
    before do
      allow(storage).to receive(:clear)
      allow(cache_store).to receive(:clear)
    end

    it 'delegates to storage' do
      decorator.clear
      expect(storage).to have_received(:clear)
    end

    context 'when caching is enabled' do
      it 'clears cache' do
        decorator.clear
        expect(cache_store).to have_received(:clear)
      end
    end

    context 'when caching is disabled' do
      let(:configuration) { instance_double('TypeBalancer::Rails::Configuration', cache_enabled: false) }

      it 'does not clear cache' do
        decorator.clear
        expect(cache_store).not_to have_received(:clear)
      end
    end
  end
end 