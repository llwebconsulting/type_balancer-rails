# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'
require 'simplecov-cobertura'
require 'timecop'
require 'active_record'
require 'yaml'

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

ENV['RAILS_ENV'] = 'test'

# Load the dummy Rails app first
require File.expand_path('dummy/config/environment', __dir__)

# Load our gem
require 'type_balancer/rails'

# Initialize TypeBalancer
TypeBalancer::Rails.initialize!

# Load all support files
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

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
  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    # Set up in-memory SQLite database
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: ':memory:'
    )

    # Load schema
    ActiveRecord::Schema.define(version: 20_240_315_000_001) do
      create_table :posts, force: :cascade do |t|
        t.string :title, null: false
        t.text :content
        t.timestamps null: false
        t.index :created_at
        t.index :title
      end
    end
  end

  # Wrap each example in a transaction
  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.before do
    TypeBalancer::Rails.reset!
    TypeBalancer::Rails.instance_variable_set(:@storage_adapter, nil)
    Rails.cache.clear
  end
end
