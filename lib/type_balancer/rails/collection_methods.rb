# frozen_string_literal: true

# lib/type_balancer/rails/collection_methods.rb
module TypeBalancer
  module Rails
    # Provides collection methods for balancing by type
    # These methods are extended onto ActiveRecord::Relation
    module CollectionMethods
      require 'digest/md5'

      def balance_by_type(options = {})
        type_field, offset, per_page = pagination_params(options)
        cache_key = build_cache_key(type_field)
        expires_in = options[:expires_in] || ::TypeBalancer::Rails.cache_expiry_seconds
        cache_reset = options[:cache_reset]
        if cache_reset
          ids = compute_ids(type_field)
          TypeBalancer::Rails.cache_adapter.write(cache_key, ids, expires_in: expires_in)
        else
          ids = TypeBalancer::Rails.cache_adapter.fetch(cache_key, expires_in: expires_in) do
            compute_ids(type_field)
          end
        end
        page_ids = ids[offset, per_page] || []
        return empty_relation if page_ids.empty?

        order_by_ids(page_ids)
      end

      private

      def pagination_params(options)
        type_field = fetch_type_field(options).to_sym
        page      = (options[:page] || 1).to_i
        per_page  = (options[:per_page] || 20).to_i
        offset    = (page - 1) * per_page
        [type_field, offset, per_page]
      end

      def build_cache_key(type_field)
        [
          'type_balancer',
          klass.name,
          type_field,
          Digest::MD5.hexdigest(to_sql)
        ].join(':')
      end

      def compute_ids(type_field)
        records     = select(:id, type_field)
        items       = records.map { |r| { id: r.id, type_field => r.public_send(type_field) } }
        type_counts = items.group_by { |h| h[type_field] }.transform_values(&:size)
        order       = compute_type_order(type_counts)
        balanced    = TypeBalancer.balance(items, type_field: type_field, type_order: order)
        balanced ? balanced.flatten(1).map { |h| h[:id] } : []
      rescue TypeBalancer::EmptyCollectionError
        []
      end

      def order_by_ids(ids)
        case_sql = "CASE id #{ids.each_with_index.map { |id, idx| "WHEN #{id} THEN #{idx}" }.join(' ')} END"
        klass.where(id: ids).order(Arel.sql(case_sql))
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
    end
  end
end
