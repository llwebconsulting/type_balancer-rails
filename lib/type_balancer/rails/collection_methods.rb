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

        type_field = fetch_type_field(options)
        # Map to array of hashes with only id and type
        id_and_type_hashes = records.map do |record|
          { id: record.id, type: record.send(type_field) }
        end
        balanced = TypeBalancer.balance(id_and_type_hashes, type_field: :type)
        return empty_relation if balanced.nil?

        paged = apply_pagination(balanced, options)
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
        ids = balanced.flatten.map { |h| h[:id] }
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
