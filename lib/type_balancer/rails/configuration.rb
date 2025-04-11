module TypeBalancer
  module Rails
    class Configuration
      attr_accessor :storage_strategy, :redis, :redis_ttl, :cursor_buffer_multiplier

      def initialize
        @storage_strategy = :cursor  # Default strategy
        @redis_ttl = 1.hour
        @cursor_buffer_multiplier = 3
      end
    end
  end
end 