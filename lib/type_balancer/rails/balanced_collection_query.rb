# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Handles querying and pagination of balanced collections
    class BalancedCollectionQuery
      attr_reader :scope, :options

      def initialize(scope, field: nil, order: nil)
        @scope = scope
        @options = {
          type_field: field || infer_type_field,
          type_order: order
        }
        @cache_key = generate_cache_key
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
        end || raise(ArgumentError, "No type field found. Please specify one using balance_by_type(field: :your_field)")
      end

      def generate_cache_key
        base = "type_balancer/#{@scope.model_name.plural}"
        scope_key = @scope.cache_key_with_version
        options_key = Digest::MD5.hexdigest(@options.to_json)
        "#{base}/#{scope_key}/#{options_key}"
      end

      def fetch_or_calculate_positions
        Rails.cache.fetch(@cache_key, expires_in: TypeBalancer::Rails.configuration.cache_duration) do
          calculate_and_store_positions
        end
      end

      def calculate_and_store_positions
        if scope.count > TypeBalancer::Rails.configuration.async_threshold
          BalanceCalculationJob.perform_later(scope, @options)
          BalancedPosition.for_collection(@cache_key)
        else
          calculate_positions
        end
      end

      def calculate_positions
        items = scope.to_a
        balancer = TypeBalancer::Balancer.new(items, type_field: @options[:type_field])
        balanced = balancer.call(order: @options[:type_order])

        balanced.each_with_index.map do |record, index|
          BalancedPosition.create!(
            record: record,
            position: index + 1,
            cache_key: @cache_key,
            type_field: @options[:type_field]
          )
        end
      end

      def paginate_by_positions(positions, page_num)
        page_positions = positions.slice(page_offset(page_num), page_size)
        scope.where(id: page_positions.map(&:record_id))
             .order(Arel.sql("FIELD(id, #{page_positions.map(&:record_id).join(',')})"))
      end

      def page_size
        @per_page || TypeBalancer::Rails.configuration.per_page_default
      end

      def page_offset(page_num)
        (page_num.to_i - 1) * page_size
      end
    end
  end
end 