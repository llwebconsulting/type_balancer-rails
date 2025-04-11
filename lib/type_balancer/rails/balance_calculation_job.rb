# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Background job for calculating balanced positions
    class BalanceCalculationJob < ActiveJob::Base
      queue_as :default

      def perform(scope, options)
        items = scope.to_a
        balancer = TypeBalancer::Balancer.new(items, type_field: options[:type_field])
        balanced = balancer.call(order: options[:type_order])

        ActiveRecord::Base.transaction do
          balanced.each_with_index do |record, index|
            BalancedPosition.create!(
              record: record,
              position: index + 1,
              cache_key: generate_cache_key(scope, options),
              type_field: options[:type_field]
            )
          end
        end

        broadcast_completion(scope.model_name.plural)
      end

      private

      def generate_cache_key(scope, options)
        base = "type_balancer/#{scope.model_name.plural}"
        scope_key = scope.cache_key_with_version
        options_key = Digest::MD5.hexdigest(options.to_json)
        "#{base}/#{scope_key}/#{options_key}"
      end

      def broadcast_completion(model_name)
        ActionCable.server.broadcast(
          "type_balancer_#{model_name}",
          { status: "completed" }
        )
      end
    end
  end
end 