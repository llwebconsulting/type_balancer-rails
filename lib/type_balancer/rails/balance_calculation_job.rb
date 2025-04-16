# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Job to calculate balance for a given type
    class BalanceCalculationJob < TypeBalancer::Rails::ApplicationJob
      queue_as :default

      def perform(relation, _options)
        manager = BackgroundPositionManager.new
        positions = manager.fetch_or_calculate(relation)

        # Store positions in the configured storage strategy
        strategy = TypeBalancer::Rails.configuration.storage_strategy
        cache_key = generate_cache_key(relation)
        strategy.store(cache_key, positions)
      end

      private

      def generate_cache_key(collection)
        base = "type_balancer/#{collection.klass.model_name.plural}"
        scope_key = collection.cache_key_with_version
        "#{base}/#{scope_key}"
      end
    end
  end
end
