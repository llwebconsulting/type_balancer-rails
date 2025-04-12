# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/lib/type_balancer/rails/version'
  enable_coverage :branch

  add_group 'Core', 'lib/type_balancer/rails'
  add_group 'ActiveRecord', 'lib/type_balancer/rails/active_record'
  add_group 'Storage', 'lib/type_balancer/rails/storage'
  add_group 'Query', 'lib/type_balancer/rails/query'
  add_group 'Config', 'lib/type_balancer/rails/config'

  formatter SimpleCov::Formatter::MultiFormatter.new([
                                                       SimpleCov::Formatter::HTMLFormatter,
                                                       SimpleCov::Formatter::CoberturaFormatter
                                                     ])
end

require 'bundler/setup'
require 'rails'
require 'active_record'
require 'active_job'
require 'redis'
require 'rspec/mocks'

# Load Rails application
require 'rails/all'

# Initialize test application
class TestApplication < Rails::Application
  config.eager_load = false
  config.active_job.queue_adapter = :test
end

Rails.application = TestApplication.new
Rails.application.config.root = File.dirname(__FILE__)
Rails.application.config.eager_load = false
Rails.logger = Logger.new($stdout)

# Load support files
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |f| require f }

# Load our gem
require 'type_balancer/rails'
require 'type_balancer/rails/configuration/storage_strategy_registry'
require 'type_balancer/rails/configuration/redis_config'
require 'type_balancer/rails/configuration/cache_config'
require 'type_balancer/rails/configuration/pagination_config'

require 'active_support'
require 'active_support/cache'
require 'active_support/cache/memory_store'

# Setup minimal Rails-like environment
module Rails
  class << self
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new(namespace: 'test')
    end

    attr_writer :cache
  end
end

RSpec.configure do |config|
  # Run all specs even after a failure, but provide options to fail-fast when needed
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end

  # Allow --fail-fast CLI option to work
  config.fail_fast = ENV['FAIL_FAST'] == 'true'

  # Run specs in random order
  config.order = :random
  Kernel.srand config.seed

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Allow focusing on specific specs with focus: true or fit
  config.filter_run_when_matching :focus

  # Allow expectations on nil to support Rails.cache mocking
  config.mock_with :rspec do |mocks|
    mocks.allow_message_expectations_on_nil = true
  end

  config.before(:suite) do
    # Initialize TypeBalancer with test configuration
    Rails.cache = ActiveSupport::Cache::MemoryStore.new(namespace: 'test')
  end

  config.before do
    # Reset TypeBalancer configuration before each test
    TypeBalancer::Rails.reset!
  end

  # Allow expectations on nil to support Rails.cache mocking
  config.include_context 'with nil expectations allowed'
end
