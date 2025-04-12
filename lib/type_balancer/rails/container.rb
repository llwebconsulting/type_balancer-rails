# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Container
      class << self
        def register(name, &block)
          registry[name] = block
        end

        def resolve(name)
          registry[name]&.call || raise(ArgumentError, "Unknown service: #{name}")
        end

        def reset!
          @registry = {}
        end

        private

        def registry
          @registry ||= {}
        end
      end
    end
  end
end
