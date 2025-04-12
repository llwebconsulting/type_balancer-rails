# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Background job for calculating and storing balanced positions
    class BalanceCalculationJob < ::ActiveJob::Base
      queue_as :default

      def perform(scope, options = {})
        @scope = scope
        @options = options

        ActiveRecord::Base.transaction do
          positions = calculate_positions
          store_positions(positions)
          broadcast_completion
        end
      end

      private

      def calculate_positions
        TypeBalancer.calculate_positions(@scope, @options)
      end

      def store_positions(positions)
        cache_key = generate_cache_key

        # Clear existing positions for this cache key
        BalancedPosition.for_collection(cache_key).delete_all

        # Store new positions
        positions.each_with_index do |record_id, index|
          BalancedPosition.create!(
            record_type: @scope.klass.name,
            record_id: record_id,
            position: index + 1,
            cache_key: cache_key,
            type_field: @options[:type_field]
          )
        end
      end

      def broadcast_completion
        channel = "type_balancer_#{@scope.klass.table_name}"
        ActionCable.server.broadcast(channel, status: 'completed')
      end

      def generate_cache_key
        base = "type_balancer/#{@scope.klass.table_name}"
        scope_key = @scope.cache_key_with_version
        options_key = Digest::MD5.hexdigest(@options.to_json)
        "#{base}/#{scope_key}/#{options_key}"
      end
    end
  end
end
