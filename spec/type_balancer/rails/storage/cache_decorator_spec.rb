# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Storage::CacheDecorator do
  let(:storage) do
    instance_double('TypeBalancer::Rails::Storage::BaseStorage').tap do |double|
      allow(double).to receive(:store)
      allow(double).to receive(:fetch)
      allow(double).to receive(:delete)
      allow(double).to receive(:clear)
      allow(double).to receive(:class).and_return(Class.new)
      allow(double.class).to receive(:name).and_return('TestStorage')
    end
  end

  let(:cache_store) do
    instance_double('ActiveSupport::Cache::Store').tap do |double|
      allow(double).to receive(:write)
      allow(double).to receive(:fetch)
      allow(double).to receive(:delete)
      allow(double).to receive(:clear)
    end
  end

  let(:decorator) { described_class.new(storage) }

  before do
    allow(Rails).to receive(:cache).and_return(cache_store)
    allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled).and_return(true)
  end

  describe '#initialize' do
    it 'wraps the provided storage' do
      expect(decorator.send(:storage)).to eq(storage)
    end

    it 'uses Rails.cache as the cache store' do
      expect(decorator.send(:cache_store)).to eq(cache_store)
    end
  end

  describe '#store' do
    let(:key) { 'test_key' }
    let(:value) { { data: 'test_value' } }
    let(:ttl) { 3600 }

    context 'when cache is enabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled).and_return(true)
      end

      it 'stores in both storage and cache' do
        expect(storage).to receive(:store).with(key, value, ttl)
        expect(cache_store).to receive(:write).with(
          "type_balancer/test_storage/#{key}",
          value,
          expires_in: ttl
        )

        decorator.store(key, value, ttl)
      end
    end

    context 'when cache is disabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled).and_return(false)
      end

      it 'only stores in storage' do
        expect(storage).to receive(:store).with(key, value, ttl)
        expect(cache_store).not_to receive(:write)

        decorator.store(key, value, ttl)
      end
    end
  end

  describe '#fetch' do
    let(:key) { 'test_key' }
    let(:value) { { data: 'test_value' } }

    context 'when cache is enabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled).and_return(true)
      end

      it 'fetches from cache first' do
        expect(cache_store).to receive(:fetch).with(
          "type_balancer/test_storage/#{key}"
        ).and_yield
        expect(storage).to receive(:fetch).with(key).and_return(value)

        result = decorator.fetch(key)
        expect(result).to eq(value)
      end
    end

    context 'when cache is disabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled).and_return(false)
      end

      it 'fetches directly from storage' do
        expect(cache_store).not_to receive(:fetch)
        expect(storage).to receive(:fetch).with(key).and_return(value)

        result = decorator.fetch(key)
        expect(result).to eq(value)
      end
    end
  end

  describe '#delete' do
    let(:key) { 'test_key' }

    context 'when cache is enabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled).and_return(true)
      end

      it 'deletes from both storage and cache' do
        expect(storage).to receive(:delete).with(key)
        expect(cache_store).to receive(:delete).with("type_balancer/test_storage/#{key}")

        decorator.delete(key)
      end
    end

    context 'when cache is disabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled).and_return(false)
      end

      it 'only deletes from storage' do
        expect(storage).to receive(:delete).with(key)
        expect(cache_store).not_to receive(:delete)

        decorator.delete(key)
      end
    end
  end

  describe '#clear' do
    context 'when cache is enabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled).and_return(true)
      end

      it 'clears both storage and cache' do
        expect(storage).to receive(:clear)
        expect(cache_store).to receive(:clear)

        decorator.clear
      end
    end

    context 'when cache is disabled' do
      before do
        allow(TypeBalancer::Rails.configuration).to receive(:cache_enabled).and_return(false)
      end

      it 'only clears storage' do
        expect(storage).to receive(:clear)
        expect(cache_store).not_to receive(:clear)

        decorator.clear
      end
    end
  end
end 