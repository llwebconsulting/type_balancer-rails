# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      # Configuration for pagination settings
      class PaginationConfig
        attr_reader :max_per_page

        def initialize(max_per_page = nil)
          @max_per_page = max_per_page
        end

        def configure
          yield(self) if block_given?
          self
        end

        def max_per_page=(value)
          @max_per_page = value&.to_i
        end

        def reset!
          @max_per_page = nil
          self
        end
      end
    end
  end
end
