# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Background job for calculating and storing balanced positions
    class BalanceCalculationJob < ::ActiveJob::Base
      queue_as :default

      def perform(relation, options)
        manager = PositionManager.new
        positions = manager.fetch_or_calculate(relation)

        # Store positions in the configured storage strategy
        strategy = ::Rails.configuration.type_balancer.storage_strategy
        cache_key = generate_cache_key(relation)
        strategy.store(cache_key, positions)
      end

      private

      def generate_cache_key(collection)
        base = "type_balancer/#{collection.model_name.plural}"
        scope_key = collection.cache_key_with_version
        "#{base}/#{scope_key}"
      end
    end
  end
end
