# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Query
      # Manages position calculation and storage for balanced collections
      class PositionManager
        attr_reader :scope, :type_field, :storage_adapter, :options

        def initialize(scope, type_field = nil, storage_adapter = nil, options = {})
          @scope = scope
          @type_field = type_field || scope&.klass&.type_field
          @storage_adapter = storage_adapter || TypeBalancer::Rails.storage_adapter
          @options = options

          validate!
        end

        def calculate_positions
          validate_scope!
          records = scope.pluck(:id, type_field)
          type_order = determine_type_order(records.map { |_, type| type }.uniq)

          positions = {}
          records.each_with_index do |(id, type), index|
            type_position = type_order.index(type) || Float::INFINITY
            positions[id] = ((type_position + 1) * 1000) + (index * 0.001)
          end

          positions
        end

        def store_positions(positions)
          positions.each do |record_id, position|
            record = scope.find(record_id)
            storage_adapter.store(
              key: cache_key(record_id),
              value: {
                record_id: record_id,
                record_type: scope.klass.name,
                position: position,
                type_value: record.public_send(type_field)
              },
              ttl: options[:ttl]
            )
          end
        end

        def fetch_positions
          record_ids = scope.pluck(:id)
          record_ids.each_with_object({}) do |record_id, result|
            if position_data = storage_adapter.fetch(key: cache_key(record_id))
              result[record_id] = position_data[:position]
            end
          end
        end

        def clear_positions
          record_ids = scope.pluck(:id)
          record_ids.each do |record_id|
            storage_adapter.delete(key: cache_key(record_id))
          end
        end

        private

        def validate!
          raise ArgumentError, 'Scope cannot be nil' if scope.nil?
          raise ArgumentError, 'Type field must be specified' if type_field.nil?
        end

        def validate_scope!
          raise ArgumentError, 'Invalid scope' unless scope.respond_to?(:pluck)
        end

        def cache_key(record_id)
          "#{scope.klass.model_name.plural}:#{record_id}"
        end

        def determine_type_order(types)
          if options[:order].present?
            options[:order]
          elsif options[:alphabetical]
            types.sort
          else
            types
          end
        end

        def calculate_max_per_type(records_by_type)
          return 0 if records_by_type.empty?

          records_by_type.values.map(&:size).max
        end
      end
    end
  end
end
