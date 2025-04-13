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
        TypeBalancer::Rails.storage_adapter.clear
      end
    end
  end
end
