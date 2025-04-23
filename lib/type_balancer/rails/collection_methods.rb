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

        # Get type field from options or model configuration
        type_field = fetch_type_field(options)

        # Balance records using TypeBalancer
        balanced = TypeBalancer.balance(records, type_field: type_field)
        return empty_relation if balanced.nil?

        # Handle pagination if requested
        if options[:page] || options[:per_page]
          page = (options[:page] || 1).to_i
          per_page = (options[:per_page] || 20).to_i
          offset = (page - 1) * per_page
          balanced = balanced[offset, per_page] || []
        end

        # Return as relation
        TestRelation.new(balanced)
      end

      def all_records = to_a

      private

      def empty_relation
        TestRelation.new([])
      end

      def fetch_type_field(options)
        model_opts = klass.respond_to?(:type_balancer_options) ? klass.type_balancer_options : {}
        options[:type_field] || model_opts[:type_field] || :type
      end
    end
  end
end
