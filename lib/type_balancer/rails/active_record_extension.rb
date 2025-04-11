module TypeBalancer
  module Rails
    module ActiveRecordExtension
      extend ActiveSupport::Concern

      included do
        class_attribute :type_field
      end

      class_methods do
        def balance_by_type(field = nil, **options)
          self.type_field = field if field

          TypeBalancerCollection.new(
            self,
            TypeBalancer::Rails.storage_strategy,
            options
          )
        end
      end
    end

    class TypeBalancerCollection
      include Enumerable

      delegate :each, :map, :to_a, to: :records

      def initialize(scope, strategy, options = {})
        @scope = scope
        @strategy = strategy
        @options = options
        @current_page = options[:page] || 1
        @per_page = options[:per_page] || 20
      end

      def page(num)
        @current_page = num
        self
      end

      def per(num)
        @per_page = num
        self
      end

      def next_page?
        !!@has_next
      end

      def total_pages
        raise NotImplementedError, "Total pages not available with cursor strategy" if @strategy.is_a?(Strategies::CursorStrategy)
        @total_pages
      end

      private

      def records
        return @records if defined?(@records)

        result, @has_next = @strategy.fetch_page(
          @scope,
          page: @current_page,
          page_size: @per_page
        )

        @records = result
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend TypeBalancer::Rails::ActiveRecordExtension
end 