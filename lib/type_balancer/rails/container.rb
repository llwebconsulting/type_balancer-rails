# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Container
      class << self
        def register(name, value = nil, cache: true, &block)
          registry[name] = if block_given?
                             {
                               block: block,
                               cache: cache
                             }
                           else
                             {
                               block: -> { value },
                               cache: true
                             }
                           end
          cache_store.delete(name)
        end

        def resolve(name)
          registration = registry.fetch(name) { raise KeyError, "Service not registered: #{name}" }

          if registration[:cache]
            cache_store[name] ||= registration[:block].call
          else
            registration[:block].call
          end
        end

        def reset!
          @registry = {}
          @cache_store = {}
        end

        private

        def registry
          @registry ||= {}
        end

        def cache_store
          @cache_store ||= {}
        end
      end
    end
  end
end
