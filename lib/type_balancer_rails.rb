# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'type_balancer'

# Core functionality
require 'type_balancer/rails/version'
require 'type_balancer/rails/errors'
require 'type_balancer/rails/core'
require 'type_balancer/rails/config'
require 'type_balancer/rails/container'

# Configuration and setup
require 'type_balancer/rails/configuration_facade'
require 'type_balancer/rails/storage_strategies'
require 'type_balancer/rails/strategies'

# ActiveRecord integration
require 'type_balancer/rails/active_record_extension'
require 'type_balancer/rails/cache_invalidation'
require 'type_balancer/rails/pagination'

# Query handling
require 'type_balancer/rails/query'
require 'type_balancer/rails/position_manager'
require 'type_balancer/rails/type_balancer_collection'

# Background processing
require 'type_balancer/rails/application_job'
require 'type_balancer/rails/balance_calculation_job'
require 'type_balancer/rails/background_processor'

# Rails integration
require 'type_balancer/rails/railtie' if defined?(Rails)

# Extend the base TypeBalancer gem with Rails integration
module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    class Error < StandardError; end

    extend ConfigurationFacade
  end
end
