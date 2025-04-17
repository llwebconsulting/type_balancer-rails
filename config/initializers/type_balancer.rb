# frozen_string_literal: true

TypeBalancer::Rails.configure do |config|
  # Enable features
  config.enable_redis
  config.enable_cache

  # Configure Redis client
  config.redis_client = Redis.new(
    url: ENV['REDIS_URL'] || 'redis://localhost:6379/0',
    timeout: 1,
    reconnect_attempts: 2
  )
  config.redis_ttl = 3600 # 1 hour

  # Configure cache settings
  config.cache_store = Rails.cache
  config.cache_ttl = 3600 # 1 hour

  # Set default storage strategy to cursor for testing
  config.storage_strategy = :cursor

  # Configure background processing threshold
  config.background_threshold = 1000
end

# Initialize the gem
TypeBalancer::Rails.load!
