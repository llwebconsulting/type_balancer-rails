# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Configuration
      attr_accessor :cursor_buffer_multiplier,
                    :background_processing_threshold,
                    :cache_enabled,
                    :cache_ttl

      def initialize
        @cursor_buffer_multiplier = 3
        @background_processing_threshold = 1000
        @cache_enabled = true
        @cache_ttl = 1.hour
      end
    end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end
    end
  end
end
