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
          @page = (options[:page] || DEFAULT_PAGE).to_i
          @per_page = [(options[:per_page] || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min
        end

        def paginate
          return collection if skip_pagination?

          if kaminari_enabled?
            paginate_with_kaminari
          elsif will_paginate_enabled?
            paginate_with_will_paginate
          else
            manual_pagination
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

        def skip_pagination?
          options[:paginate] == false
        end

        def kaminari_enabled?
          defined?(Kaminari) && collection.respond_to?(:page)
        end

        def will_paginate_enabled?
          defined?(WillPaginate::Collection) && collection.respond_to?(:paginate)
        end

        def paginate_with_kaminari
          collection.page(page).per(per_page)
        end

        def paginate_with_will_paginate
          collection.paginate(page: page, per_page: per_page)
        end

        def manual_pagination
          collection
            .offset(offset)
            .limit(per_page)
        end

        def offset
          (page - 1) * per_page
        end

        def total_count
          @total_count ||= collection.count
        end
      end
    end
  end
end
