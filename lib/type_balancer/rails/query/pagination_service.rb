# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Query
      # Handles pagination for balanced collections with support for multiple pagination libraries
      class PaginationService
        DEFAULT_PAGE = 1
        DEFAULT_PER_PAGE = 25
        MAX_PER_PAGE = 100

        def initialize(collection, options = {})
          @collection = collection
          @options = options
          @paginate = options.fetch(:paginate, true)
          @total_count = nil

          begin
            @page = Integer(options[:page] || 1)
            @page = [@page, 1].max
          rescue ArgumentError
            @page = 0
          end

          begin
            @per_page = Integer(options[:per_page] || DEFAULT_PER_PAGE)
            @per_page = if @per_page <= 0
                          DEFAULT_PER_PAGE
                        else
                          [@per_page, MAX_PER_PAGE].min
                        end
          rescue ArgumentError
            @per_page = DEFAULT_PER_PAGE
          end
        end

        def paginate
          return collection unless @paginate

          if collection.respond_to?(:page)
            paginate_with_kaminari
          elsif collection.respond_to?(:paginate)
            paginate_with_will_paginate
          else
            paginate_manually
          end
        end

        def next_page?
          total_count > (page * per_page)
        end

        def prev_page?
          page > 1
        end

        def total_pages
          (total_count.to_f / per_page).ceil
        end

        def current_page
          page
        end

        private

        attr_reader :collection, :options, :page, :per_page

        def paginate_with_kaminari
          collection.page(@page).per(@per_page)
        end

        def paginate_with_will_paginate
          collection.paginate(page: @page, per_page: @per_page)
        end

        def paginate_manually
          validate_manual_pagination_methods!
          collection.offset(offset).limit(limit_value)
        end

        def validate_manual_pagination_methods!
          return if collection.respond_to?(:offset) && collection.respond_to?(:limit) && collection.respond_to?(:count)

          raise NoMethodError, 'Collection must respond to :offset, :limit, and :count for manual pagination'
        end

        def offset
          (page - 1) * per_page
        end

        def total_count
          @total_count ||= collection.count
        end

        def limit_value
          per_page
        end
      end
    end
  end
end
