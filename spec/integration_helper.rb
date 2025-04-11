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

# Configure ActiveRecord
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Load support files first
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].sort.each { |f| require f }

# Load our gem
require 'type_balancer/rails'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Database cleaner
  config.before(:suite) do
    # Create test schema
    require_relative 'support/schema'
  end

  config.after do
    # Clean up database after each test
    Post.delete_all
    TypeBalancer::Rails::BalancedPosition.delete_all
  end
end
