# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Configuration
      # Configuration for Redis
      class RedisConfig
        attr_reader :client, :ttl

        def initialize(ttl: 3600)
          @enabled = false
          @ttl = ttl
          @client = nil
        end

        def configure
          require 'redis'
          @client = Redis.new
          yield(self) if block_given?
          @enabled = true
          self
        end

        def register_client(client)
          @client = client
          @enabled = true
          self
        end

        def enabled?
          @enabled
        end

        def ttl=(value)
          @ttl = value.to_i
        end

        def reset!
          @enabled = false
          @client = nil
          @ttl = 3600
        end
      end
    end
  end
end
