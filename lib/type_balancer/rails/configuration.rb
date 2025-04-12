# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Configuration
      attr_accessor :cursor_buffer_multiplier,
                    :background_processing_threshold,
                    :cache_enabled,
                    :cache_ttl,
                    :storage_strategy,
                    :redis_client

      def initialize
        @cursor_buffer_multiplier = 3
        @background_processing_threshold = 1000
        @cache_enabled = true
        @cache_ttl = 1.hour
        @storage_strategy = :cursor
      end
    end

    class << self
      attr_accessor :configuration

      def configure
        self.configuration ||= Configuration.new
        yield(configuration)
      end

      def storage_strategy
        container.resolve(:storage_strategy)
      end

      def container
        @container ||= Container.new
      end

      def reset!
        @configuration = Configuration.new
        @container = Container.new
      end
    end
  end
end
