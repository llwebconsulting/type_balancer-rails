# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
require 'simplecov-cobertura'
require 'timecop'
require 'yaml'
require 'mock_redis'
require 'database_cleaner'

# Configure SimpleCov
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

# Configure RSpec
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  config.before do
    TypeBalancer::Rails.reset!
    TypeBalancer::Rails.instance_variable_set(:@storage_adapter, nil)
    Rails.cache.clear
  end
end
