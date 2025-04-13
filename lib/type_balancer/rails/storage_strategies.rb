# frozen_string_literal: true

require_relative 'strategies/base_strategy'
require_relative 'strategies/redis_strategy'
require_relative 'strategies/memory_strategy'
require_relative 'strategies/cursor_strategy'
require_relative 'strategies/storage_adapter'

module TypeBalancer
  module Rails
    # Module containing all storage strategies
    module Strategies
      extend ActiveSupport::Autoload
    end
  end
end
