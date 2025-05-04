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
      attr_accessor :cache_adapter
    end
    self.cache_adapter ||= TypeBalancer::Rails::CacheAdapter.new
  end
end
