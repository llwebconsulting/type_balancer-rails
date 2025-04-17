# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Query
      # Handles basic query construction operations like ordering and conditions
      class QueryBuilder
        attr_reader :scope

        def initialize(scope)
          @scope = scope
        end

        def apply_order(order)
          return scope unless order

          order_clause = sanitize_order(order)
          scope.order(order_clause)
        end

        def apply_conditions(conditions)
          return scope if conditions.blank?

          scope.where(conditions)
        end

        private

        def sanitize_order(order)
          case order
          when Symbol, String
            order.to_s
          when Array
            order.map(&:to_s)
          when Hash
            order.transform_values(&:to_s)
          else
            raise ArgumentError, 'Invalid order format'
          end
        end
      end
    end
  end
end
