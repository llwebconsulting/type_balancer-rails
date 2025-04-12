# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Config::StorageAdapter do
  let(:valid_redis_client) do
    double('RedisClient',
           get: nil,
           set: nil,
           setex: nil,
           del: nil,
           flushdb: nil)
  end

  let(:valid_cache_store) do
    double('CacheStore',
           read: nil,
           write: nil,
           delete: nil,
           clear: nil)
  end

  before do
    described_class.reset!
  end

  describe '.configure_redis' do
    it 'configures valid redis client' do
      expect {
        described_class.configure_redis(valid_redis_client)
      }.not_to raise_error

      expect(described_class.redis_client).to eq valid_redis_client
      expect(described_class).to be_redis_enabled
    end

    it 'raises error for invalid redis client' do
      invalid_client = double('InvalidClient')

      expect {
        described_class.configure_redis(invalid_client)
      }.to raise_error(described_class::InvalidRedisClientError)
    end
  end

  describe '.configure_cache' do
    it 'configures valid cache store' do
      expect {
        described_class.configure_cache(valid_cache_store)
      }.not_to raise_error

      expect(described_class.cache_store).to eq valid_cache_store
    end

    it 'raises error for invalid cache store' do
      invalid_store = double('InvalidStore')

      expect {
        described_class.configure_cache(invalid_store)
      }.to raise_error(described_class::InvalidCacheStoreError)
    end
  end

  describe '.redis_enabled?' do
    it 'returns true when redis is properly configured' do
      described_class.configure_redis(valid_redis_client)
      expect(described_class).to be_redis_enabled
    end

    it 'returns false when redis is not configured' do
      expect(described_class).not_to be_redis_enabled
    end
  end

  describe '.reset!' do
    before do
      described_class.configure_redis(valid_redis_client)
      described_class.configure_cache(valid_cache_store)
    end

    it 'resets all configurations' do
      described_class.reset!

      expect(described_class.redis_client).to be_nil
      expect(described_class.cache_store).to be_nil
      expect(described_class).not_to be_redis_enabled
    end
  end
end 