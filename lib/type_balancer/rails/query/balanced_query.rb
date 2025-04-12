# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Query
      # Handles building and manipulation of balanced collection queries
      class BalancedQuery
        attr_reader :scope, :options

        def initialize(scope, options = {})
          @scope = extract_scope(scope)
          @options = default_options.merge(options)
          @type_field = options[:type_field]
        end

        def build
          validate!
          apply_type_field
          apply_order
          apply_conditions
          scope
        end

        def with_options(new_options)
          self.class.new(scope, options.merge(new_options))
        end

        private

        attr_reader :type_field

        def extract_scope(scope_or_hash)
          return scope_or_hash[:collection] if scope_or_hash.is_a?(Hash) && scope_or_hash[:collection]

          scope_or_hash
        end

        def default_options
          {
            order: nil,
            conditions: {},
            type_field: nil
          }
        end

        def validate!
          raise ArgumentError, 'Scope cannot be nil' if scope.nil?
          raise ArgumentError, 'Scope must be an ActiveRecord::Relation' unless scope.is_a?(ActiveRecord::Relation)

          return if type_field || inferred_type_field

          raise ArgumentError, 'No type field found. Please specify one using type_field: :your_field'
        end

        def apply_type_field
          @type_field ||= inferred_type_field
        end

        def apply_order
          return unless options[:order]

          order_clause = sanitize_order(options[:order])
          @scope = scope.order(order_clause)
        end

        def apply_conditions
          return if options[:conditions].empty?

          @scope = scope.where(options[:conditions])
        end

        def inferred_type_field
          %w[type media_type content_type category].find do |field|
            scope.column_names.include?(field)
          end
        end

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
