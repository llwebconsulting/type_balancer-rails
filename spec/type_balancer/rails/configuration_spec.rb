# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Configuration do
  after(:each) do
    TypeBalancer::Rails.reset_configuration!
    TypeBalancer::Rails::Container.reset!
  end

  describe '.configure' do
    it 'yields configuration instance when block given' do
      expect { |b| TypeBalancer::Rails.configure(&b) }
        .to yield_with_args(TypeBalancer::Rails::Configuration)
    end

    it 'registers default storage strategies' do
      TypeBalancer::Rails.configure {}
      
      expect(TypeBalancer::Rails::Container.resolve(:cursor_strategy))
        .to be_a(TypeBalancer::Rails::StorageStrategies::CursorStrategy)
    end

    it 'allows configuration of cursor buffer multiplier' do
      TypeBalancer::Rails.configure do |config|
        config.cursor_buffer_multiplier = 5
      end

      strategy = TypeBalancer::Rails::Container.resolve(:cursor_strategy)
      expect(strategy.buffer_multiplier).to eq(5)
    end

    it 'allows configuration of background processing threshold' do
      TypeBalancer::Rails.configure do |config|
        config.background_processing_threshold = 1000
      end

      expect(TypeBalancer::Rails.configuration.background_processing_threshold).to eq(1000)
    end

    it 'allows configuration of cache settings' do
      TypeBalancer::Rails.configure do |config|
        config.cache_enabled = true
        config.cache_ttl = 2.hours
      end

      expect(TypeBalancer::Rails.configuration.cache_enabled).to be true
      expect(TypeBalancer::Rails.configuration.cache_ttl).to eq(2.hours)
    end
  end

  describe '#redis_enabled?' do
    it 'returns false when redis is not configured' do
      config = described_class.new
      expect(config.redis_enabled?).to be false
    end

    it 'returns true when redis client is registered' do
      config = described_class.new
      redis_client = double('Redis')
      config.register_redis_client(redis_client)
      expect(config.redis_enabled?).to be true
    end
  end

  describe '#register_redis_client' do
    it 'sets redis client and enables redis' do
      config = described_class.new
      redis_client = double('Redis')
      
      config.register_redis_client(redis_client)
      
      expect(config.redis_client).to eq(redis_client)
      expect(config.redis_enabled).to be true
    end

    it 'registers redis strategy with container' do
      config = described_class.new
      redis_client = double('Redis')
      
      config.register_redis_client(redis_client)
      
      expect(TypeBalancer::Rails::Container.resolve(:redis_strategy))
        .to be_a(TypeBalancer::Rails::StorageStrategies::RedisStrategy)
    end

    it 'configures redis strategy with provided TTL' do
      config = described_class.new
      redis_client = double('Redis')
      
      config.register_redis_client(redis_client, ttl: 2.hours)
      
      strategy = TypeBalancer::Rails::Container.resolve(:redis_strategy)
      expect(strategy.instance_variable_get(:@default_ttl)).to eq(2.hours)
    end
  end

  describe 'default storage strategy resolution' do
    let(:redis_client) { double('Redis') }

    it 'resolves to cursor strategy by default' do
      TypeBalancer::Rails.configure {}
      
      strategy = TypeBalancer::Rails::Container.resolve(:default_storage_strategy)
      expect(strategy).to be_a(TypeBalancer::Rails::StorageStrategies::CursorStrategy)
    end

    it 'resolves to redis strategy when redis is enabled' do
      TypeBalancer::Rails.configure do |config|
        config.register_redis_client(redis_client)
      end
      
      strategy = TypeBalancer::Rails::Container.resolve(:default_storage_strategy)
      expect(strategy).to be_a(TypeBalancer::Rails::StorageStrategies::RedisStrategy)
    end

    it 'allows overriding default strategy' do
      custom_strategy = Class.new(TypeBalancer::Rails::StorageStrategies::BaseStrategy)
      TypeBalancer::Rails.configure do |config|
        config.register_storage_strategy(:custom, custom_strategy)
        config.default_storage_strategy = :custom
      end
      
      strategy = TypeBalancer::Rails::Container.resolve(:default_storage_strategy)
      expect(strategy).to be_a(custom_strategy)
    end
  end

  describe '#register_storage_strategy' do
    let(:custom_strategy) { Class.new(TypeBalancer::Rails::StorageStrategies::BaseStrategy) }

    it 'registers new strategy with container' do
      config = described_class.new
      config.register_storage_strategy(:custom, custom_strategy)
      
      expect(TypeBalancer::Rails::Container.resolve(:custom_strategy))
        .to be_a(custom_strategy)
    end

    it 'validates strategy inheritance' do
      config = described_class.new
      invalid_strategy = Class.new
      
      expect {
        config.register_storage_strategy(:invalid, invalid_strategy)
      }.to raise_error(ArgumentError, /must inherit from BaseStrategy/)
    end

    it 'allows strategy configuration' do
      config = described_class.new
      config.register_storage_strategy(:custom, custom_strategy, option: 'value')
      
      strategy = TypeBalancer::Rails::Container.resolve(:custom_strategy)
      expect(strategy.instance_variable_get(:@options)).to include(option: 'value')
    end
  end
end 