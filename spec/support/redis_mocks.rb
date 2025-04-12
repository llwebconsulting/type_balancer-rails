# frozen_string_literal: true

module RedisMocks
  def mock_redis_client
    instance_double(
      Redis,
      set: true,
      get: nil,
      del: 1,
      flushdb: true,
      exists?: false,
      multi: ->(block) { block.call },
      exec: [],
      expire: true,
      ttl: -1
    )
  end

  def mock_redis_client_with_data(data = {})
    instance_double(
      Redis,
      set: true,
      get: ->(key) { data[key] },
      del: ->(key) { data.delete(key) ? 1 : 0 },
      flushdb: lambda {
        data.clear
        true
      },
      exists?: ->(key) { data.key?(key) },
      multi: ->(block) { block.call },
      exec: [],
      expire: true,
      ttl: -1
    )
  end
end

RSpec.configure do |config|
  config.include RedisMocks
end
