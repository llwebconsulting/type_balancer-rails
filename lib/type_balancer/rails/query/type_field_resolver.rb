# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Query
      # Handles resolution of type fields in ActiveRecord models
      class TypeFieldResolver
        COMMON_TYPE_FIELDS = %w[type media_type content_type category].freeze

        attr_reader :scope

        def initialize(scope)
          @scope = scope
        end

        def resolve(explicit_field = nil)
          return explicit_field if explicit_field
          return scope.type_field if scope.respond_to?(:type_field) && scope.type_field

          inferred_type_field || raise(
            ArgumentError,
            'No type field found. Please specify one using type_field: :your_field'
          )
        end

        private

        def inferred_type_field
          COMMON_TYPE_FIELDS.find do |field|
            scope.klass.column_names.include?(field)
          end
        end
      end
    end
  end
end
