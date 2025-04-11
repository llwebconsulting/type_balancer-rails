# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/numeric/time'
require 'active_record'
require 'active_job'
require 'redis'
require 'type_balancer'

module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    extend ActiveSupport::Autoload

    # Configuration defaults
    mattr_accessor :cache_duration, default: 1.hour
    mattr_accessor :async_threshold, default: 1000
    mattr_accessor :per_page_default, default: 25
    mattr_accessor :max_per_page, default: 100

    class << self
      def configure
        yield self
      end
    end
  end
end

require_relative 'rails/version'
require_relative 'rails/balanced_position'
require_relative 'rails/cache_invalidation'
require_relative 'rails/balance_calculation_job'
require_relative 'rails/balanced_collection_query'

# Include CacheInvalidation in ActiveRecord::Base for testing
ActiveRecord::Base.include TypeBalancer::Rails::CacheInvalidation
