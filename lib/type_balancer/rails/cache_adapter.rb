module TypeBalancer
  module Rails
    class CacheAdapter
      def initialize
        @memory_cache = {}
      end

      def fetch(key, options = {}, &block)
        if defined?(::Rails) && ::Rails.respond_to?(:cache) && ::Rails.cache
          ::Rails.cache.fetch(key, options, &block)
        else
          @memory_cache[key] ||= block.call
        end
      end

      def write(key, value, options = {})
        if defined?(::Rails) && ::Rails.respond_to?(:cache) && ::Rails.cache
          ::Rails.cache.write(key, value, options)
        else
          @memory_cache[key] = value
        end
      end

      def delete(key)
        if defined?(::Rails) && ::Rails.respond_to?(:cache) && ::Rails.cache
          ::Rails.cache.delete(key)
        else
          @memory_cache.delete(key)
        end
      end

      def clear_cache!
        ::Rails.cache.clear if defined?(::Rails) && ::Rails.respond_to?(:cache) && ::Rails.cache
        @memory_cache.clear
      end
    end
  end
end
