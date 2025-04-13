module TypeBalancer
  module Rails
    class Pagination
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      def initialize(per_page: nil, page: nil)
        @per_page = [per_page || DEFAULT_PER_PAGE, MAX_PER_PAGE].min
        @page = page || 1
      end

      def apply_to(relation, positions)
        page_positions = positions.slice(page_offset, @per_page)
        return relation.none if page_positions.empty?

        record_ids = page_positions.keys
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
