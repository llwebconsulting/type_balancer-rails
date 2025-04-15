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

      class StrategyManager
        attr_reader :strategies

        def initialize
          @strategies = {}
        end

        def register(name, strategy)
          @strategies[name] = strategy
        end

        delegate :[], to: :strategies

        def validate!
          raise TypeBalancer::Rails::Errors::ConfigurationError, 'No strategies registered' if strategies.empty?

          strategies.each_value do |strategy|
            unless strategy.respond_to?(:store) && strategy.respond_to?(:fetch)
              raise TypeBalancer::Rails::Errors::StrategyError,
                    "Invalid strategy: #{strategy}"
            end
          end
          true
        end

        def reset!
          @strategies = {}
        end
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
