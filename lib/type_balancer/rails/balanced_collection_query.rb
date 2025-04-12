# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Handles querying and pagination of balanced collections
    class BalancedCollectionQuery
      attr_reader :scope, :options

      def initialize(scope, options = {})
        @scope = scope[:collection] if scope.is_a?(Hash) && scope[:collection]
        @scope ||= scope
        @options = options
        @per_page = options[:per_page] || 25
      end

      def execute
        fetch_or_calculate_positions
      end

      def background_processing?
        scope.count > TypeBalancer::Rails.configuration.background_processing_threshold
      end

      def page(num)
        positions = fetch_or_calculate_positions
        paginate_by_positions(positions, num)
      end

      def per(count)
        @per_page = [
          count.to_i,
          TypeBalancer::Rails.configuration.max_per_page
        ].min
        self
      end

      private

      def infer_type_field
        %w[type media_type content_type category].find do |field|
          scope.column_names.include?(field)
        end || raise(ArgumentError, 'No type field found. Please specify one using balance_by_type(field: :your_field)')
      end

      def fetch_or_calculate_positions
        cache_key = generate_cache_key

        ::Rails.cache.fetch(cache_key, expires_in: TypeBalancer::Rails.configuration.cache_ttl) do
          calculate_and_store_positions
        end
      end

      def calculate_and_store_positions
        # Calculate positions using the core gem
        positions = TypeBalancer.calculate_positions(@scope, @options)

        # Store positions in the database
        store_positions(positions)

        # Return the positions
        positions
      end

      def store_positions(positions)
        cache_key = generate_cache_key

        ActiveRecord::Base.transaction do
          # Clear existing positions for this cache key
          BalancedPosition.for_collection(cache_key).delete_all

          # Store new positions
          positions.each_with_index do |record_id, index|
            BalancedPosition.create!(
              record_type: scope.klass.name,
              record_id: record_id,
              position: index + 1,
              cache_key: cache_key,
              type_field: @options[:type_field]
            )
          end
        end
      end

      def paginate_by_positions(positions, page_num)
        offset = (page_num - 1) * @per_page
        page_positions = positions[offset, @per_page] || []

        # Return empty scope if no positions for this page
        return @scope.none if page_positions.empty?

        # Order by the calculated positions
        @scope.where(id: page_positions)
              .order(Arel.sql("FIELD(id, #{page_positions.join(',')})"))
      end

      def generate_cache_key
        base = "type_balancer/#{scope.klass.table_name}"
        scope_key = scope.cache_key_with_version
        options_key = Digest::MD5.hexdigest(@options.to_json)
        "#{base}/#{scope_key}/#{options_key}"
      end
    end
  end
end
