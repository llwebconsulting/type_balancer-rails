# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'active_record'

require_relative 'rails/active_record_extension'
require_relative 'rails/collection_methods'
require_relative 'rails/cache_adapter'

module TypeBalancer
  module Rails
    class << self
      attr_accessor :cache_adapter, :cache_expiry_seconds

      def clear_cache!
        cache_adapter&.clear_cache!
      end
    end
    self.cache_adapter ||= TypeBalancer::Rails::CacheAdapter.new
    self.cache_expiry_seconds ||= 600 # 10 minutes default
  end
end
