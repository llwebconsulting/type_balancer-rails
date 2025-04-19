# frozen_string_literal: true

require 'simplecov'
require 'simplecov-cobertura'
require 'timecop'
require 'active_record'
require 'spec_helper'
require 'rails'
require 'active_job'
require 'action_cable'
require 'type_balancer/rails'

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
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('dummy/config/environment', __dir__)

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'

# Initialize TypeBalancer after Rails is loaded
TypeBalancer::Rails.initialize!

# Configure Rails Environment
Rails.application.configure do
  config.cache_classes = true
  config.eager_load = false
  config.public_file_server.enabled = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.active_job.queue_adapter = :test
  config.action_cable.disable_request_forgery_protection = true
  config.active_support.deprecation = :stderr
end

# Configure TypeBalancer to use Rails cache
TypeBalancer::Rails.configure do |config|
  config.enable_cache
  config.cache_store = Rails.cache
  config.configure_cache
end

# Set up the test database
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Load schema
load File.expand_path('dummy/db/schema.rb', __dir__)

# Verify schema loaded correctly
tables = ActiveRecord::Base.connection.tables
puts "Available tables after schema load: #{tables.inspect}"
raise "Could not find table 'posts'" unless tables.include?('posts')

# Configure DatabaseCleaner
RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end

# Set up ActiveJob
ActiveJob::Base.queue_adapter = :test

# Load support files
Dir[File.join(__dir__, 'support/**/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  config.before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
  end

  # Wrap each example in a transaction
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
