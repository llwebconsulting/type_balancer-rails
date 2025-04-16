# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      # Configuration for pagination settings
      class PaginationConfig
        attr_accessor :max_per_page

        def initialize(max_per_page = 100)
          value = max_per_page.is_a?(Hash) ? max_per_page[:max_per_page] : max_per_page
          value = value.nil? ? 100 : value.to_i
          @max_per_page = value > 0 ? value : 100
        end

        def configure
          yield(self) if block_given?
          self
        end

        def set_max_per_page(value)
          value = value.to_i
          @max_per_page = value if value > 0
          self
        end

        def reset!
          @max_per_page = 100
          self
        end
      end
    end
  end
end
