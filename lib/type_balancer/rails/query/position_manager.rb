# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Query
      # Manages position calculation and storage for balanced collections
      class PositionManager
        def initialize(scope, options = {})
          @scope = scope
          @options = options
          @storage = options.fetch(:storage) { default_storage }
          @type_field = options[:type_field]
        end

        def calculate_positions
          validate_scope!
          group_and_calculate
        end

        def store_positions(positions)
          positions.each_with_index do |record, index|
            storage.store(
              record_id: record.id,
              record_type: record.class.name,
              position: index + 1,
              type_field: type_field,
              type_value: record.public_send(type_field)
            )
          end
        end

        def fetch_positions
          storage.fetch_for_scope(scope)
        end

        def clear_positions
          storage.clear_for_scope(scope)
        end

        private

        attr_reader :scope, :options, :storage, :type_field

        def validate_scope!
          raise ArgumentError, 'Scope cannot be nil' if scope.nil?
          raise ArgumentError, 'Scope must be an ActiveRecord::Relation' unless scope.is_a?(ActiveRecord::Relation)
          raise ArgumentError, 'Type field must be specified' unless type_field
        end

        def group_and_calculate
          records_by_type = scope.group_by { |record| record.public_send(type_field) }
          balance_groups(records_by_type)
        end

        def balance_groups(records_by_type)
          types = determine_type_order(records_by_type.keys)
          balanced_records = []

          max_per_type = calculate_max_per_type(records_by_type)
          current_indexes = Hash.new(0)

          until balanced_records.length == scope.count
            types.each do |type|
              records = records_by_type[type] || []
              index = current_indexes[type]

              if index < records.length && index < max_per_type
                balanced_records << records[index]
                current_indexes[type] += 1
              end
            end
          end

          balanced_records
        end

        def determine_type_order(available_types)
          return options[:order] if options[:order].present?
          return available_types.sort if options[:order_alphabetically]

          available_types
        end

        def calculate_max_per_type(records_by_type)
          counts = records_by_type.values.map(&:length)
          return 0 if counts.empty?

          counts.max
        end

        def default_storage
          TypeBalancer::Rails::StorageStrategies::CursorStrategy.new
        end
      end
    end
  end
end
