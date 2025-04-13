# frozen_string_literal: true

require_relative 'query/query_builder'
require_relative 'query/type_field_resolver'
require_relative 'query/balanced_query'
require_relative 'query/pagination_service'
require_relative 'query/position_manager'

module TypeBalancer
  module Rails
    # Query module that ties together all query-related components
    module Query
      class << self
        def build(scope, options = {})
          BalancedQuery.new(scope, options).build
        end
      end
    end
  end
end
