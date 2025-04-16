module TypeBalancer
  module Rails
    module Query
      class CursorService
        attr_reader :scope, :strategy, :current_page, :per_page

        def initialize(scope, strategy: nil)
          @scope = scope
          @strategy = strategy || TypeBalancer::Rails::Strategies::CursorStrategy.new
          @total_count = nil
          @current_page = 1
          @per_page = 25
        end

        def paginate(page: 1, per_page: 25)
          validate_pagination_params!(page, per_page)
          @current_page = page
          @per_page = per_page

          positions = fetch_positions(page, per_page)
          return scope.none if positions.empty?

          start_pos, end_pos = positions
          scope.where(position: start_pos..end_pos).order(:position)
        rescue StandardError => e
          raise TypeBalancer::Rails::Errors::PaginationError, e.message
        end

        def total_count
          @total_count ||= scope.count
        end

        def total_pages
          (total_count.to_f / per_page).ceil
        end

        def next_page
          return nil if total_count <= current_page * per_page

          current_page + 1
        end

        def prev_page
          return nil if current_page <= 1

          current_page - 1
        end

        private

        def validate_pagination_params!(page, per_page)
          raise ArgumentError, 'Page must be greater than 0' if page < 1
          raise ArgumentError, 'Per page must be greater than 0' if per_page < 1
        end

        def fetch_positions(page, per_page)
          offset = (page - 1) * per_page
          limit = per_page

          strategy.fetch_positions(scope, offset: offset, limit: limit)
        end
      end
    end
  end
end
