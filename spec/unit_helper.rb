# frozen_string_literal: true

require "simplecov"
require "simplecov-cobertura"

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter
]

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/lib/type_balancer/rails/version"
  
  add_group "Core", "lib/type_balancer/rails"
  add_group "ActiveRecord", "lib/type_balancer/rails/active_record"
  add_group "Strategies", "lib/type_balancer/rails/strategies"
end

require "bundler/setup"
require "rails"
require "active_record"
require "active_job"
require "redis"
require "rspec/mocks"

# Load our gem
require "type_balancer/rails"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Mock ActiveRecord::Base for unit tests
  config.before(:each) do
    # Setup common mocks
    allow(ActiveRecord::Base).to receive(:include).and_return(true)
    allow(Rails.cache).to receive(:fetch).and_yield
    allow(Rails.cache).to receive(:delete_matched)
  end
end 