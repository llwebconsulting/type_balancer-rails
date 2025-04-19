# frozen_string_literal: true

# This integration test requires Redis to be running locally.
# See README.md for Redis installation and setup instructions.
# In CI environments, Redis is automatically provisioned as a service container.

require 'spec_helper'
require 'rails_helper'
require 'redis'

RSpec.describe 'Redis Integration' do
  let(:redis_client) { Redis.new }
  let(:test_key) { 'test:integration:key' }
  let(:test_value) { { foo: 'bar', timestamp: Time.current.to_i } }
  let(:test_ttl) { 3600 }

  before(:all) do
    # Reset TypeBalancer configuration before all tests
    TypeBalancer::Rails.reset!
  end

  before do
    # Clean up any existing test keys
    redis_client.del(test_key)

    # Configure TypeBalancer with Redis
    TypeBalancer::Rails.configure do |config|
      # Configure Redis
      config.enable_redis
      config.configure_redis(redis_client)
      config.redis_ttl = test_ttl
      config.storage_strategy = :redis

      # Configure pagination
      config.max_per_page = 100
      config.cursor_buffer_multiplier = 2

      # Explicitly disable cache
      config.disable_cache
    end
  end

  after do
    # Clean up test keys
    redis_client.del(test_key)
    TypeBalancer::Rails.reset!
  end

  describe 'Redis Configuration' do
    it 'properly configures Redis' do
      expect(TypeBalancer::Rails.redis_enabled?).to be true
      expect(TypeBalancer::Rails.redis_client).to eq(redis_client)
      expect(TypeBalancer::Rails.redis_ttl).to eq(test_ttl)
    end

    it 'validates Redis connection' do
      expect { TypeBalancer::Rails.validate! }.not_to raise_error
    end
  end

  describe 'Redis Storage Operations' do
    let(:storage_adapter) { TypeBalancer::Rails.storage_adapter }

    it 'stores and retrieves values' do
      # Store value
      storage_adapter.store(test_key, test_value, test_ttl)

      # Verify TTL is set
      ttl = redis_client.ttl(test_key)
      expect(ttl).to be_between(0, test_ttl)

      # Retrieve and verify value
      retrieved_value = storage_adapter.fetch(test_key)
      expect(retrieved_value).to eq(test_value)
    end

    it 'handles non-existent keys' do
      expect(storage_adapter.fetch('non:existent:key')).to be_nil
    end

    it 'deletes keys' do
      storage_adapter.store(test_key, test_value, test_ttl)
      expect(storage_adapter.fetch(test_key)).to eq(test_value)

      storage_adapter.delete(test_key)
      expect(storage_adapter.fetch(test_key)).to be_nil
    end

    it 'clears all keys for a scope' do
      scope_keys = [
        'test:scope:1:key1',
        'test:scope:1:key2',
        'test:scope:1:key3'
      ]

      # Store multiple keys
      scope_keys.each do |key|
        storage_adapter.store(key, test_value, test_ttl)
      end

      # Verify keys exist
      scope_keys.each do |key|
        expect(storage_adapter.fetch(key)).to eq(test_value)
      end

      # Clear scope
      storage_adapter.clear_for_scope('test:scope:1')

      # Verify keys are deleted
      scope_keys.each do |key|
        expect(storage_adapter.fetch(key)).to be_nil
      end
    end
  end

  describe 'Redis Strategy Integration' do
    let(:collection) { double('TestCollection', object_id: 'test123') }
    let(:strategy) do
      TypeBalancer::Rails::Strategies::RedisStrategy.new(collection, TypeBalancer::Rails.storage_adapter)
    end

    it 'uses proper key namespacing' do
      key = 'test_key'
      strategy.store(key, test_value)

      # Verify the key is stored with proper namespace
      namespaced_key = "type_balancer:test123:#{key}"
      raw_value = redis_client.get(namespaced_key)
      expect(raw_value).not_to be_nil

      # Verify value can be retrieved through strategy
      retrieved_value = strategy.fetch(key)
      expect(retrieved_value).to eq(test_value)
    end

    it 'handles JSON serialization' do
      complex_value = {
        string: 'test',
        number: 42,
        array: [1, 2, 3],
        nested: {
          a: 1,
          b: 'two',
          c: [true, false]
        },
        timestamp: Time.current.to_i
      }

      strategy.store('complex_key', complex_value)
      retrieved_value = strategy.fetch('complex_key')
      expect(retrieved_value).to eq(complex_value)
    end
  end
end
