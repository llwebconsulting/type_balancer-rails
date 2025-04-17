# frozen_string_literal: true

module TypeBalancer
  module Rails
    class BackgroundProcessor
      DEFAULT_ASYNC_THRESHOLD = 1000

      class << self
        def should_process_async?(collection_size)
          collection_size > async_threshold
        end

        private

        def async_threshold
          if defined?(::Rails) && ::Rails.configuration.respond_to?(:type_balancer)
            ::Rails.configuration.type_balancer.async_threshold || DEFAULT_ASYNC_THRESHOLD
          else
            DEFAULT_ASYNC_THRESHOLD
          end
        end
      end
    end
  end
end
