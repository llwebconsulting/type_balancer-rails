# frozen_string_literal: true

require "bundler/setup"
require "simplecov"
require "simplecov-cobertura"

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/lib/type_balancer/rails/version"
  enable_coverage :branch

  add_group "Core", "lib/type_balancer/rails"
  add_group "ActiveRecord", "lib/type_balancer/rails/active_record"
  add_group "Storage", "lib/type_balancer/rails/storage"
  add_group "Query", "lib/type_balancer/rails/query"
  add_group "Config", "lib/type_balancer/rails/config"

  formatter SimpleCov::Formatter::MultiFormatter.new([
                                                       SimpleCov::Formatter::HTMLFormatter,
                                                       SimpleCov::Formatter::CoberturaFormatter
                                                     ])

  minimum_coverage 95
  minimum_coverage_by_file 80
end

require "rails"
require "active_support"
require "active_support/cache"
require "active_support/cache/memory_store"
require "redis"
require "rspec/mocks"

# Initialize test application
class TestApplication < Rails::Application
  config.eager_load = false
end

Rails.application = TestApplication.new
Rails.application.config.root = File.dirname(__FILE__)
Rails.application.config.eager_load = false
Rails.logger = Logger.new($stdout)

# Setup minimal Rails-like environment
module Rails
  class << self
    def cache
      @cache ||= ActiveSupport::Cache::MemoryStore.new(namespace: "test")
    end

    attr_writer :cache
  end
end

# Load our gem
require "type_balancer/rails"

# Initialize TypeBalancer with test configuration
TypeBalancer::Rails.initialize!

# Load all support files
Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].sort.each { |f| require f }

# Configure RSpec
RSpec.configure do |config|
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true unless meta.key?(:aggregate_failures)
  end

  config.fail_fast = ENV["FAIL_FAST"] == "true"
  config.order = :random
  Kernel.srand config.seed

  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.filter_run_when_matching :focus

  config.mock_with :rspec do |mocks|
    mocks.allow_message_expectations_on_nil = true
  end

  config.before(:suite) do
    Rails.cache = ActiveSupport::Cache::MemoryStore.new(namespace: "test")
  end

  config.before do
    TypeBalancer::Rails.reset!
  end

  # Clear any stored data between tests
  config.before do
    TypeBalancer::Rails.instance_variable_set(:@storage_adapter, nil)
  end
end
