# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Handles cache invalidation for balanced collections
    module CacheInvalidation
      extend ActiveSupport::Concern

      included do
        include ::ActiveRecord::Callbacks
        after_commit :invalidate_type_balancer_cache
      end

      def invalidate_type_balancer_cache
        puts 'Invalidating type balancer cache...'
        TypeBalancer::Rails.storage_adapter.clear if TypeBalancer::Rails.respond_to?(:storage_adapter)
        puts "Cache enabled: #{TypeBalancer::Rails.configuration.cache_enabled}"
        ::Rails.cache.clear if TypeBalancer::Rails.configuration.cache_enabled
        puts 'Cache cleared!'
      end
    end
  end
end
