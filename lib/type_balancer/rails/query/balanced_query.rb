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
          @query_builder = QueryBuilder.new(@scope)
          @type_field_resolver = TypeFieldResolver.new(@scope)
        end

        def build
          validate!
          apply_type_field
          apply_order
          apply_conditions
          query_builder.scope
        end

        def with_options(new_options)
          self.class.new(scope, options.merge(new_options))
        end

        private

        attr_reader :query_builder, :type_field_resolver, :resolved_type_field

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

          @resolved_type_field = type_field_resolver.resolve(options[:type_field])
          return if @resolved_type_field

          raise ArgumentError, 'No type field found. Please specify one using type_field: :your_field'
        end

        def apply_type_field
          @resolved_type_field
        end

        def apply_order
          return unless options[:order]

          query_builder.apply_order(options[:order])
        end

        def apply_conditions
          return if options[:conditions].empty?

          query_builder.apply_conditions(options[:conditions])
        end
      end
    end
  end
end
