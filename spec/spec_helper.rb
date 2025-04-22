# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
require 'simplecov-cobertura'

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

# Load Rails and its components first
require 'rails'
require 'active_record'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'active_job/railtie'

# Load testing dependencies
require 'rspec/rails'
require 'action_cable/testing/rspec'
require 'timecop'
require 'yaml'
require 'mock_redis'
require 'database_cleaner'

# Set up Rails environment
ENV['RAILS_ENV'] = 'test'
require File.expand_path('../spec/dummy/config/environment.rb', __dir__)

# Load our gem
require 'type_balancer/rails'

# Load all support files
Dir[File.join(__dir__, 'support/**/*.rb')].sort.each { |f| require f }

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

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.start
    TypeBalancer::Rails.reset!
    TypeBalancer::Rails.instance_variable_set(:@storage_adapter, nil)
    Rails.cache.clear
  end

  config.after do
    DatabaseCleaner.clean
  end
end
