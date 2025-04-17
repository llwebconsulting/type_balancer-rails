# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Pagination
      extend ActiveSupport::Concern

      DEFAULT_PER_PAGE = 100
      MAX_PER_PAGE = 1000

      included do
        scope :paginate, lambda { |page: 1, per_page: DEFAULT_PER_PAGE|
          per_page = [per_page.to_i, MAX_PER_PAGE].min
          page = [page.to_i, 1].max
          offset = (page - 1) * per_page

          positions = TypeBalancer::Rails::Query::PositionManager.new(self).calculate_positions
          return none if positions.empty?

          record_ids = positions.keys[offset, per_page]
          return none if record_ids.blank?

          where(id: record_ids).reorder(position_order_clause(record_ids))
        }
      end

      class_methods do
        private

        def position_order_clause(record_ids)
          Arel.sql("FIELD(id, #{record_ids.join(',')})")
        end
      end
    end
  end
end
