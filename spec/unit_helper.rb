# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter
]

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/lib/type_balancer/rails/version'

  add_group 'Core', 'lib/type_balancer/rails'
  add_group 'ActiveRecord', 'lib/type_balancer/rails/active_record'
  add_group 'Strategies', 'lib/type_balancer/rails/strategies'
end

require 'bundler/setup'
require 'rails'
require 'active_record'
require 'active_job'
require 'redis'
require 'rspec/mocks'

# Load our gem
require 'type_balancer/rails'
require 'type_balancer/rails/strategies'
require 'type_balancer/rails/strategies/base_strategy'
require 'type_balancer/rails/container'
require 'type_balancer/rails/cache_invalidation'

# Set up a mock Rails cache for testing
require 'active_support/cache/memory_store'
Rails.cache = ActiveSupport::Cache::MemoryStore.new

# Load support files after loading our gem
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

# Configure RSpec
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Allow expectations on nil to support Rails.cache mocking
  config.mock_with :rspec do |mocks|
    mocks.allow_message_expectations_on_nil = true
  end

  # Clean up between tests
  config.before do
    Rails.cache.clear
  end
end
