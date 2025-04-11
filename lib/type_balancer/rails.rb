# frozen_string_literal: true

require "active_support"
require "active_record"
require "type_balancer"
require_relative "rails/version"

module TypeBalancer
  # Rails integration for TypeBalancer
  module Rails
    extend ActiveSupport::Autoload

    autoload :BalancedCollectionQuery
    autoload :BalancedPosition
    autoload :CacheInvalidation

    # Configuration class for TypeBalancer::Rails
    class Configuration
      attr_accessor :cache_duration, :async_threshold, :per_page_default, :max_per_page

      def initialize
        @cache_duration = 1.hour
        @async_threshold = 1000
        @per_page_default = 25
        @max_per_page = 100
      end
    end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end
    end

    # Extend ActiveRecord with type balancing capabilities
    module ActiveRecordExtension
      extend ActiveSupport::Concern

      class_methods do
        def balance_by_type(field: nil, order: nil)
          TypeBalancer::Rails::BalancedCollectionQuery.new(
            all,
            field: field,
            order: order
          )
        end
      end
    end
  end
end

# Extend ActiveRecord::Base with TypeBalancer functionality
ActiveSupport.on_load(:active_record) do
  include TypeBalancer::Rails::ActiveRecordExtension
end
