# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Handles cache invalidation for balanced collections
    module CacheInvalidation
      extend ActiveSupport::Concern

      included do
        include ::ActiveRecord::Callbacks
        after_commit :invalidate_balance_cache, if: :persisted?
      end

      def invalidate_balance_cache
        # Delete all cache entries for this model type
        ::Rails.cache.delete_matched("type_balancer/#{self.class.table_name}/*")

        # Delete all balanced positions for this record
        TypeBalancer::Rails::BalancedPosition.where(
          record_type: self.class.name,
          record_id: id
        ).delete_all
      end
    end
  end
end
