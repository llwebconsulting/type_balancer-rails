# frozen_string_literal: true

require 'active_support/all'
require 'active_record'
require 'active_job'
require 'redis'
require 'type_balancer'

# First load all configuration-related files
require_relative 'rails/config/storage_adapter'
require_relative 'rails/config/base_configuration'
require_relative 'rails/config/validation_behavior'
require_relative 'rails/config/runtime_configuration'
require_relative 'rails/config'
require_relative 'rails/configuration_facade'
require_relative 'rails/core'

# Then load the rest of the files
require_relative 'rails/query'
require_relative 'rails/version'
require_relative 'rails/cache_invalidation'
require_relative 'rails/application_job'
require_relative 'rails/balance_calculation_job'
require_relative 'rails/container'
require_relative 'rails/storage_strategies'
require_relative 'rails/strategies'
require_relative 'rails/pagination'
require_relative 'rails/position_manager'
require_relative 'rails/background_processor'
require_relative 'rails/strategies/base_strategy'
require_relative 'rails/strategies/cursor_strategy'
require_relative 'rails/strategies/redis_strategy'
require_relative 'rails/query/position_manager'
require_relative 'rails/active_record_extension'
require 'type_balancer/rails/errors'

# Load railtie last since it uses the configuration
require_relative 'rails/railtie' if defined?(Rails)

module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    extend ActiveSupport::Autoload
    extend ConfigurationFacade

    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100
    BACKGROUND_THRESHOLD = 1000

    def self.balance_collection(relation, options = {})
      Query::BalancedQuery.new(relation, options).build
    end
  end
end

# Include CacheInvalidation in ActiveRecord::Base for testing
ActiveSupport.on_load(:active_record) { include TypeBalancer::Rails::CacheInvalidation }

TypeBalancer::Rails.initialize!
