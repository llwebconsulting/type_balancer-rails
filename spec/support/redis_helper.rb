# frozen_string_literal: true

require 'mock_redis'

module RedisHelper
  def mock_redis
    @mock_redis ||= MockRedis.new
  end

  def with_mocked_redis
    allow(Redis).to receive(:new).and_return(mock_redis)
    allow(TypeBalancer::Rails).to receive(:redis_client).and_return(mock_redis)
    yield if block_given?
  end

  def setup_test_cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new(
      namespace: 'type_balancer_test',
      size: 32.megabytes
    )
    Rails.cache.clear
  end

  def cleanup_test_cache
    Rails.cache.clear
  end
end

RSpec.configure do |config|
  config.include RedisHelper

  config.before do
    # Reset mock Redis before each test
    @mock_redis = nil
  end

  config.before do
    setup_test_cache
  end

  config.after do
    cleanup_test_cache
  end
end
