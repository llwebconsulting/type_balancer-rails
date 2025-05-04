# frozen_string_literal: true

# lib/type_balancer/rails/collection_methods.rb
module TypeBalancer
  module Rails
    # Provides collection methods for balancing by type
    # These methods are extended onto ActiveRecord::Relation
    module CollectionMethods
      require 'digest/md5'

      def balance_by_type(options = {})
        type_field = fetch_type_field(options).to_sym
        page     = (options[:page] || 1).to_i
        per_page = (options[:per_page] || 20).to_i
        offset   = (page - 1) * per_page

        cache_key = [
          'type_balancer',
          klass.name,
          type_field,
          Digest::MD5.hexdigest(to_sql)
        ].join(':')

        ids = TypeBalancer::Rails.cache_adapter.fetch(cache_key, expires_in: 10.minutes) do
          items = select(:id, type_field).map { |r| { id: r.id, type_field => r.public_send(type_field) } }
          type_counts = items.group_by { |h| h[type_field] }.transform_values(&:size)
          type_order = type_counts.sort_by { |_, v| v }.map(&:first)
          begin
            balanced = TypeBalancer.balance(items, type_field: type_field, type_order: type_order)
          rescue TypeBalancer::EmptyCollectionError
            return empty_relation
          end
          balanced ? balanced.flatten(1).map { |h| h[:id] } : []
        end

        page_ids = ids[offset, per_page] || []
        return empty_relation if page_ids.empty?

        case_sql = "CASE id #{page_ids.each_with_index.map { |id, idx| "WHEN #{id} THEN #{idx}" }.join(' ')} END"
        klass.where(id: page_ids).order(Arel.sql(case_sql))
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
