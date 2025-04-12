# frozen_string_literal: true

require_relative '../strategies'

module TypeBalancer
  module Rails
    module Strategies
      class CursorStrategy < Strategy
        def execute
          buffer_size = collection_query.per_page * TypeBalancer::Rails.configuration.cursor_buffer_multiplier

          # Get a buffer of records to balance from
          records = collection_query.base_scope
                                    .limit(buffer_size)
                                    .offset(collection_query.offset)
                                    .to_a

          # Balance the records for the current page
          TypeBalancer::Core::Balancer.new(
            records,
            collection_query.type_field,
            collection_query.per_page
          ).balance
        end
      end
    end
  end
end
