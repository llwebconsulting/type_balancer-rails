# frozen_string_literal: true

# lib/type_balancer/rails/collection_methods.rb
module TypeBalancer
  module Rails
    # Provides collection methods for balancing by type
    # These methods are extended onto ActiveRecord::Relation
    module CollectionMethods
      def balance_by_type(options = {})
        records = to_a
        return empty_relation if records.empty?

        type_field = fetch_type_field(options).to_sym
        type_counts = records.group_by { |r| r.send(type_field).to_s }.transform_values(&:count)
        type_order = compute_type_order(type_counts)
        items = build_items(records, type_field)

        balanced = TypeBalancer.balance(
          items,
          type_field: type_field,
          type_order: type_order
        )

        return empty_relation if balanced.nil?

        paged = apply_pagination(balanced, options)

        build_result(paged)
      end

      private

      def apply_pagination(records, options)
        return records unless options[:page] || options[:per_page]

        page     = (options[:page] || 1).to_i
        per_page = (options[:per_page] || 20).to_i
        offset   = (page - 1) * per_page
        records[offset, per_page] || []
      end

      def build_result(balanced)
        flattened = balanced.flatten(1)
        ids = flattened.map { |h| h[:id] }
        unless klass.respond_to?(:where)
          raise TypeError, 'balance_by_type can only be called on an ActiveRecord::Relation or compatible object'
        end

        relation = klass.where(id: ids)
        if ids.any?
          case_sql = "CASE id #{ids.each_with_index.map { |id, idx| "WHEN #{id} THEN #{idx}" }.join(' ')} END"
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

      def compute_type_order(type_counts)
        type_counts.sort_by { |_, count| count }.map(&:first)
      end

      def build_items(records, type_field)
        records.map do |record|
          { id: record.id, type_field => record.send(type_field).to_s }
        end
      end

      def logger?
        defined?(::Rails) && ::Rails.logger
      end

      def balance_results_lines(balanced, _type_field)
        if balanced.nil?
          ['Balanced result is nil!']
        else
          [
            "First 10 balanced types: \#{balanced.first(10).map { |h| h[type_field] }.inspect}",
            "Unique types in first 10: \#{balanced.first(10).map { |h| h[type_field] }.uniq.inspect}",
            "Total balanced items: \#{balanced.size}"
          ]
        end
      end
    end
  end
end
