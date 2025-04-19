# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Configuration module that ties together all configuration components
    module Config
      class << self
        def configure
          yield TypeBalancer::Rails.configuration if block_given?
          self
        end

        delegate :configuration, to: :'TypeBalancer::Rails'

        delegate :reset!, to: :'TypeBalancer::Rails'

        delegate :load!, to: :'TypeBalancer::Rails'
      end

      class CacheConfig
        attr_accessor :enabled, :ttl

        def initialize(enabled: true, ttl: 1.hour)
          @enabled = enabled
          @ttl = ttl
        end

        def configure
          yield(::Rails.cache) if block_given?
        end

        def reset!
          @enabled = true
          @ttl = 1.hour
        end
      end

      class RedisConfig
        attr_accessor :client, :enabled

        def initialize(enabled: true)
          @enabled = enabled
          @client = nil
        end

        def configure
          yield(self) if block_given?
        end

        def reset!
          @enabled = true
          @client = nil
        end
      end
    end
  end
end
