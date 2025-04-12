# frozen_string_literal: true

module TypeBalancer
  module Rails
    module Config
      # Handles pure configuration settings for TypeBalancer Rails
      class Configuration
        attr_accessor :cache_enabled,
                      :cache_ttl,
                      :redis_ttl,
                      :cursor_buffer_multiplier,
                      :background_processing_threshold,
                      :max_per_page

        def initialize
          set_defaults
        end

        def reset!
          set_defaults
        end

        private

        def set_defaults
          @cache_enabled = true
          @cache_ttl = 1.hour
          @redis_ttl = 1.hour
          @cursor_buffer_multiplier = 1.5
          @background_processing_threshold = 1000
          @max_per_page = 100
        end
      end
    end
  end
end
