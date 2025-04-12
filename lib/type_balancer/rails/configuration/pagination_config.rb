# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Configuration
      # Configuration for pagination
      class PaginationConfig
        attr_reader :max_per_page, :cursor_buffer_multiplier

        def initialize(max_per_page: 100, cursor_buffer_multiplier: 1.5)
          @max_per_page = max_per_page
          @cursor_buffer_multiplier = cursor_buffer_multiplier
        end

        def set_max_per_page(value)
          value = value.to_i
          return if value <= 0

          @max_per_page = value
        end

        def set_buffer_multiplier(value)
          value = value.to_f
          return if value <= 1.0

          @cursor_buffer_multiplier = value
        end

        def reset!
          @max_per_page = 100
          @cursor_buffer_multiplier = 1.5
        end
      end
    end
  end
end
