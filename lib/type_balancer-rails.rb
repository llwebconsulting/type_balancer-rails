require 'active_support'
require 'active_support/core_ext'
require 'type_balancer'

require 'type_balancer/rails/container'
require 'type_balancer/rails/strategy_registry'
require 'type_balancer/rails/configuration'
require 'type_balancer/rails/strategies/base_strategy'
require 'type_balancer/rails/strategies/cursor_strategy'
require 'type_balancer/rails/strategies/redis_strategy'
require 'type_balancer/rails/storage/base_storage'
require 'type_balancer/rails/storage/memory_storage'
require 'type_balancer/rails/active_record_extension'
require 'type_balancer/rails'

# Extend the base TypeBalancer gem with Rails integration
module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    class Error < StandardError; end

    class << self
      def configure
        yield configuration if block_given?
        self
      end

      def configuration
        @configuration ||= Configuration.new
      end

      def reset!
        @configuration = nil
      end
    end
  end
end
