module TypeBalancer
  module Rails
    module Strategies
      class CursorStrategy < BaseStrategy
        def initialize(buffer_multiplier: 3)
          @buffer_multiplier = buffer_multiplier
        end

        def fetch_page(scope, page_size: 20, cursor: nil)
          scope = cursor ? scope.where("id > ?", cursor) : scope
          records = scope.limit(page_size * @buffer_multiplier).to_a
          
          balanced = TypeBalancer.balance(records, type_field: scope.type_field)
          paginated = balanced.first(page_size)
          
          [paginated, paginated.last&.id]
        end

        def next_page_token(result)
          result.last # Returns the cursor (last ID)
        end
      end
    end
  end
end 