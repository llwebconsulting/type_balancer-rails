module TypeBalancer
  module Rails
    class Pagination
      DEFAULT_PER_PAGE = 100
      MAX_PER_PAGE = 1000

      def initialize(positions = [], per_page: DEFAULT_PER_PAGE, page: 1)
        @positions = positions
        @per_page = [per_page.to_i, MAX_PER_PAGE].min
        @page = [page.to_i, 1].max
      end

      def apply_to(relation)
        return relation.none if @positions.empty?

        page_positions = @positions.slice(page_offset, @per_page)
        record_ids = page_positions.map { |pos| pos[:id] }

        relation
          .where(id: record_ids)
          .reorder(position_order_clause(record_ids))
      end

      private

      def page_offset
        (@page - 1) * @per_page
      end

      def position_order_clause(record_ids)
        Arel.sql("FIELD(id, #{record_ids.join(',')})")
      end
    end
  end
end
