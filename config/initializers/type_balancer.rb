# frozen_string_literal: true

TypeBalancer::Rails.configure do |config|
  # Configure Redis client
  config.configure_redis do |redis|
    redis.url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'
    redis.options = {
      timeout: 1,
      reconnect_attempts: 2,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    }
  end

  # Configure cache settings
  config.configure_cache do |cache|
    cache.options = {
      namespace: 'type_balancer',
      expires_in: 1.hour
    }
  end

  # Set default storage strategy to Redis
  config.storage_strategy = :redis

  # Configure background processing threshold
  config.background_threshold = TypeBalancer::Rails::BACKGROUND_THRESHOLD
end

# Initialize TypeBalancer
TypeBalancer::Rails.initialize!
