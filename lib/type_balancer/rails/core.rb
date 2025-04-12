# frozen_string_literal: true

require 'active_support'

module TypeBalancer
  module Rails
    # Core configuration module
    module Core
      module ConfigurationFacade
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def configuration
            @configuration ||= Configuration.new
          end

          def configure
            yield configuration if block_given?
            self
          end

          def reset!
            configuration.reset!
            self
          end
        end
      end

      extend ConfigurationFacade::ClassMethods

      class Configuration
        attr_accessor :strategy_manager, :storage_adapter, :redis_client, :cache_ttl

        def initialize
          reset!
        end

        def configure_redis
          yield @redis_client if block_given?
          self
        end

        def configure_cache
          yield ::Rails.cache if block_given?
          self
        end

        def reset!
          @strategy_manager = nil
          @storage_adapter = nil
          @redis_client = nil
          @cache_ttl = 3600
        end
      end
    end
  end
end
