# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Handles position calculation and caching for background jobs
    class BackgroundPositionManager
      def initialize(strategy: ::Rails.configuration.type_balancer.storage_strategy)
        @strategy = strategy
      end

      def fetch_or_calculate(collection)
        cache_key = generate_cache_key(collection)
        @strategy.fetch(cache_key) do
          calculate_positions(collection)
        end
      end

      private

      def calculate_positions(collection)
        positions = {}
        collection.pluck(:id).each_with_index do |id, index|
          positions[id] = index + 1
        end
        positions
      end

      def generate_cache_key(collection)
        base = "type_balancer/#{collection.model_name.plural}"
        scope_key = collection.cache_key_with_version
        "#{base}/#{scope_key}"
      end
    end
  end
end
