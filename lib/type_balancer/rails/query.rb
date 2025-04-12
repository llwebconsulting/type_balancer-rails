# frozen_string_literal: true

require_relative 'query/balanced_query'

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
