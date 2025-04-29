# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Provides collection methods for balancing by type
    # These methods are extended onto ActiveRecord::Relation
    module CollectionMethods
      # Public: Balance the collection by type
      #
      # options - Hash of options to merge with model's type_balancer_options (default: {})
      #          :type_field - Field to balance by (default: :type)
      #          :page      - Page number for pagination (default: 1)
      #          :per_page  - Number of items per page (default: 20)
      #
      # Examples
      #
      #   Post.all.balance_by_type
      #   Post.where(published: true).balance_by_type(type_field: :category)
      #   Post.all.balance_by_type(page: 2, per_page: 20)
      #
      # Returns ActiveRecord::Relation with balanced ordering
      def balance_by_type(options = {})
        records = to_a
        return empty_relation if records.empty?

        type_field = fetch_type_field(options).to_sym

        # Get all unique types and their counts
        type_counts = records.group_by { |r| r.send(type_field).to_s }
                             .transform_values(&:count)

        # Sort types by count ascending to prioritize less common types
        type_order = type_counts.sort_by { |_, count| count }
                                .map { |type, _| type }

        # Convert records to hashes that TypeBalancer can process
        items = records.map do |record|
          {
            id: record.id,
            type_field => record.send(type_field).to_s # Use the actual type field name
          }
        end

        # Debug output (only if logger is available)
        if defined?(::Rails) && ::Rails.logger
          ::Rails.logger.debug "\n[TypeBalancer] Debug Information:"
          ::Rails.logger.debug '===================='
          ::Rails.logger.debug "Type field: #{type_field}"
          ::Rails.logger.debug "Type counts: #{type_counts.inspect}"
          ::Rails.logger.debug "Type order: #{type_order.inspect}"
          ::Rails.logger.debug "Sample of input items: #{items.first(2).inspect}"
          ::Rails.logger.debug "Total records: #{records.size}"
          ::Rails.logger.debug '===================='
        end

        # Pass the records to TypeBalancer with the actual type field
        balanced = TypeBalancer.balance(
          items,
          type_field: type_field,
          type_order: type_order
        )

        if defined?(::Rails) && ::Rails.logger
          ::Rails.logger.debug "\n[TypeBalancer] Balance Results:"
          ::Rails.logger.debug '===================='
          if balanced.nil?
            ::Rails.logger.debug 'Balanced result is nil!'
          else
            ::Rails.logger.debug "First 10 balanced types: #{balanced.first(10).map { |h| h[type_field] }.inspect}"
            ::Rails.logger.debug "Unique types in first 10: #{balanced.first(10).map do |h|
              h[type_field]
            end.uniq.inspect}"
            ::Rails.logger.debug "Total balanced items: #{balanced.size}"
          end
          ::Rails.logger.debug '===================='
        end

        return empty_relation if balanced.nil?

        paged = apply_pagination(balanced, options)

        if defined?(::Rails) && ::Rails.logger
          ::Rails.logger.debug "\n[TypeBalancer] Final Results:"
          ::Rails.logger.debug '===================='
          ::Rails.logger.debug "First 10 paged IDs: #{paged.first(10).map { |h| h[:id] }.inspect}"
          ::Rails.logger.debug '===================='
        end

        build_result(paged)
      end

      private

      def apply_pagination(records, options)
        return records unless options[:page] || options[:per_page]

        page      = (options[:page] || 1).to_i
        per_page  = (options[:per_page] || 20).to_i
        offset    = (page - 1) * per_page
        records[offset, per_page] || []
      end

      def build_result(balanced)
        ids = balanced.map { |h| h[:id] }
        unless klass.respond_to?(:where)
          raise TypeError, 'balance_by_type can only be called on an ActiveRecord::Relation or compatible object'
        end

        relation = klass.where(id: ids)
        if ids.any?
          # PostgreSQL CASE statement for custom ordering
          case_sql = 'CASE id ' + ids.each_with_index.map { |id, idx| "WHEN #{id} THEN #{idx}" }.join(' ') + ' END'
          relation = relation.order(Arel.sql(case_sql))
        end
        relation
      end

      def empty_relation
        unless klass.respond_to?(:none)
          raise TypeError, 'balance_by_type can only be called on an ActiveRecord::Relation or compatible object'
        end

        klass.none
      end

      def fetch_type_field(options)
        model_opts = klass.respond_to?(:type_balancer_options) ? klass.type_balancer_options : {}
        options[:type_field] || model_opts[:type_field] || :type
      end
    end
  end
end
