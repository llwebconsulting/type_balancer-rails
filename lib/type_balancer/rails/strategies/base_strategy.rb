# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Strategies
      class BaseStrategy
        def initialize(collection, options = {})
          @collection = collection
          @options = options
        end

        def execute
          raise NotImplementedError, "#{self.class} must implement #execute"
        end

        # @param scope [ActiveRecord::Relation] The scope to fetch records from
        # @param page_size [Integer] Number of records per page
        # @param cursor [String, Integer] Cursor for pagination (optional)
        # @return [Array<Object>, Object] Array of [records, pagination_token]
        def fetch_page(scope, page_size: 20, cursor: nil)
          raise NotImplementedError, "#{self.class} must implement #fetch_page"
        end

        # @param result [Array<Object>] The records from the last fetch
        # @return [Object] Token for the next page
        def next_page_token(result)
          raise NotImplementedError, "#{self.class} must implement #next_page_token"
        end

        # @return [Boolean] Whether this strategy supports total pages count
        def supports_total_pages?
          false
        end

        # @param scope [ActiveRecord::Relation] The scope to count pages for
        # @param page_size [Integer] Number of records per page
        # @return [Integer, nil] Total number of pages or nil if not supported
        def total_pages(scope, page_size:)
          nil
        end

        private

        attr_reader :collection, :options
      end
    end
  end
end
