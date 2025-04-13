module TypeBalancer
  module Rails
    class BalancedQuery
      def initialize(relation, options = {})
        @relation = relation
        @options = options
        @pagination = Pagination.new(
          per_page: options[:per_page],
          page: options[:page]
        )
        @position_manager = PositionManager.new
      end

      def execute
        return process_async if should_process_async?

        positions = @position_manager.fetch_or_calculate(@relation)
        @pagination.apply_to(@relation, positions)
      end

      private

      def should_process_async?
        @options[:async] && BackgroundProcessor.should_process_async?(@relation.count)
      end

      def process_async
        BalanceCalculationJob.perform_later(@relation, @options)
        @relation.none
      end
    end
  end
end
