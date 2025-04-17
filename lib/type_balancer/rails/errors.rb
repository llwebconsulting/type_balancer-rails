# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Module containing all TypeBalancer Rails errors
    module Errors
      # Base error class for all TypeBalancer errors
      class Error < StandardError; end

      # Raised when configuration validation fails
      class ConfigurationError < Error; end

      # Raised when a strategy validation fails
      class StrategyError < Error; end

      # Raised when cache operations fail
      class CacheError < Error; end

      # Raised when Redis operations fail
      class RedisError < Error; end

      # Raised when invalid input is provided
      class ValidationError < Error; end

      # Raised when a required dependency is missing
      class DependencyError < Error; end

      # Raised when pagination operations fail
      class PaginationError < Error; end
    end
  end
end
