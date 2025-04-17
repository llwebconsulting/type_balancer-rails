# frozen_string_literal: true

module RedisHelper
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
    setup_test_cache
  end

  config.after do
    cleanup_test_cache
  end
end
