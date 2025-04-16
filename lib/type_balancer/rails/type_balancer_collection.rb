# frozen_string_literal: true

module TypeBalancer
  module Rails
    module TypeBalancerCollection
      extend ActiveSupport::Concern

      included do
        include Enumerable
        delegate :each, :map, :to_a, to: :records
      end

      def initialize(scope, options = {})
        @scope = scope
        @options = options.dup # Prevent mutation of original options
        @cache_key = generate_cache_key
        setup_dependencies
      end

      def page(num)
        @pagination = @pagination.page(num)
        @cache_key = generate_cache_key
        self
      end

      def per(num)
        @pagination = @pagination.per(num)
        @cache_key = generate_cache_key
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

      def setup_dependencies
        @query = Query::BalancedQuery.new(@scope, @options)
        @position_manager = Query::PositionManager.new(@scope, @options)
        @pagination = Query::PaginationService.new(@scope, @options)
      end

      def generate_cache_key
        components = [
          @scope.cache_key_with_version,
          @options.hash,
          @pagination&.current_page,
          @pagination&.per_page
        ]
        Digest::MD5.hexdigest(components.join('-'))
      end

      def records
        return @records if defined?(@records)

        # Try to fetch from cache first
        @records = Rails.cache.fetch(@cache_key, expires_in: 1.hour) do
          fetch_records
        end
      rescue StandardError => e
        Rails.logger.error("Error in TypeBalancerCollection#records: #{e.message}")
        fetch_records # Fallback to direct fetch if cache fails
      end

      def fetch_records
        balanced_scope = @query.build
        positions = @position_manager.calculate_positions
        @position_manager.store_positions(positions)
        @pagination.paginate(balanced_scope)
      end
    end
  end
end
