# frozen_string_literal: true

require 'redis'
require 'mock_redis'

# Configure Redis for the test environment
if Rails.env.test?
  $redis = MockRedis.new
else
  redis_config = {
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1'),
    timeout: 1,
    reconnect_attempts: 2,
    driver: :ruby
  }
  $redis = Redis.new(redis_config)
end

# Configure TypeBalancer to use Redis
TypeBalancer::Rails.configure do |config|
  config.enable_redis
  config.redis_client = $redis
  config.redis_ttl = 1.hour
  config.storage_strategy = :redis
end

# Clear Redis database on Rails boot in test environment
$redis.flushdb if Rails.env.test?
