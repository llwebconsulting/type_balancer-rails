require 'active_support'
require 'active_support/core_ext'
require 'type_balancer'

require 'type_balancer/rails/container'
require 'type_balancer/rails/strategy_registry'
require 'type_balancer/rails/configuration'
require 'type_balancer/rails/strategies/base_strategy'
require 'type_balancer/rails/strategies/cursor_strategy'
require 'type_balancer/rails/strategies/redis_strategy'
require 'type_balancer/rails/active_record_extension'
require 'type_balancer/rails'

module TypeBalancer
  module Rails
    class Error < StandardError; end
  end
end 