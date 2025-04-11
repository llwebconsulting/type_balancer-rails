# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Handles cache invalidation for balanced collections
    module CacheInvalidation
      extend ActiveSupport::Concern

      included do
        after_commit :invalidate_balance_cache
      end

      private

      def invalidate_balance_cache
        base_key = "type_balancer/#{self.class.name.underscore.pluralize}"
        cache_key = "#{base_key}/#{cache_key_with_version}"
        
        ::Rails.cache.delete_matched("#{base_key}/*")
        BalancedPosition.where(record: self).delete_all
      end
    end
  end
end 