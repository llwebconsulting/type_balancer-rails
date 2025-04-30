# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  add_filter '/spec/'
  add_filter '/vendor/'
  minimum_coverage line: 80 # Set line coverage only since our branch coverage is low
end

require 'rspec'
require 'active_support'
require 'ostruct'

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'type_balancer_rails'
require 'type_balancer/rails/collection_methods'
require 'type_balancer/rails/active_record_extension'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.order = :random
  config.seed = Kernel.rand(1_000_000)
end

# Mock ActiveRecord::Base
module ActiveRecord
  # Mock of ActiveRecord::Base for testing without database connection
  # Only implements the minimum interface needed for tests
  class Base
    def self.all
      []
    end
  end
end
