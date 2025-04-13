# frozen_string_literal: true

module TypeBalancer
  module Rails
    module ActiveRecordExtension
      extend ActiveSupport::Concern

      included do
        class_attribute :type_field
        include TypeBalancer::Rails::CacheInvalidation
      end

      module ClassMethods
        def balance_by_type(field = nil, **options)
          self.type_field = field if field

          TypeBalancerCollection.new(
            self,
            options.merge(type_field: type_field)
          )
        end
      end

      class TypeBalancerCollection
        include Enumerable

        delegate :each, :map, :to_a, to: :records

        def initialize(scope, options = {})
          @scope = scope
          @options = options
          @query = Query::BalancedQuery.new(scope, options)
          @position_manager = Query::PositionManager.new(scope, options)
          @pagination = Query::PaginationService.new(scope, options)
        end

        def page(num)
          @pagination = @pagination.page(num)
          self
        end

        def per(num)
          @pagination = @pagination.per(num)
          self
        end

        delegate :next_page?, to: :@pagination
        delegate :prev_page?, to: :@pagination
        delegate :total_pages, to: :@pagination
        delegate :current_page, to: :@pagination

        # @deprecated Use {#per} instead
        def per_page(num)
          ActiveSupport::Deprecation.warn(
            'TypeBalancerCollection#per_page is deprecated and will be removed in the next major version. ' \
            'Use #per instead.',
            caller
          )
          per(num)
        end

        private

        def records
          return @records if defined?(@records)

          balanced_scope = @query.build
          positions = @position_manager.calculate_positions
          @position_manager.store_positions(positions)

          @records = @pagination.paginate(balanced_scope)
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend TypeBalancer::Rails::ActiveRecordExtension
end
