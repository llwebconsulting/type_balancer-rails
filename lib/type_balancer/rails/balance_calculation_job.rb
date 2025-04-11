# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Background job for calculating and storing balanced positions
    class BalanceCalculationJob < ::ActiveJob::Base
      queue_as :default

      def perform(scope, options = {})
        # Calculate positions using the core gem
        positions = TypeBalancer.calculate_positions(scope, options)

        # Store positions in the database
        store_positions(positions, options)

        # Broadcast completion if needed
        broadcast_completion if options[:broadcast]
      end

      private

      def store_positions(positions, options)
        cache_key = generate_cache_key(options)

        # Store each position in a transaction
        ActiveRecord::Base.transaction do
          positions.each_with_index do |record_id, index|
            BalancedPosition.create!(
              record_type: options[:record_type],
              record_id: record_id,
              position: index + 1,
              cache_key: cache_key,
              type_field: options[:type_field]
            )
          end
        end
      end

      def generate_cache_key(options)
        base = "type_balancer/#{options[:record_type].tableize}"
        scope_key = options[:scope_key]
        options_key = Digest::MD5.hexdigest(options.except(:scope_key, :record_type).to_json)
        "#{base}/#{scope_key}/#{options_key}"
      end

      def broadcast_completion
        # Implementation depends on the notification system being used
        # (ActionCable, Hotwire, etc.)
      end
    end
  end
end
