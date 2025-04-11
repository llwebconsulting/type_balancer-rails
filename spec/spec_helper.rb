# frozen_string_literal: true

require "bundler/setup"
require "active_record"
require "action_controller/railtie"
require "active_job/railtie"
require "action_cable/engine"
require "rspec/rails"
require "type_balancer/rails"

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Configure ActiveRecord
ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)

# Configure ActionCable
module TestApp
  class Application < Rails::Application
    config.eager_load = false
    config.active_job.queue_adapter = :test
    config.cache_store = :memory_store
  end
end

# Load support files
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    # Create test schema
    ActiveRecord::Schema.define do
      create_table :posts do |t|
        t.string :title
        t.string :media_type
        t.timestamps
      end

      create_table :type_balancer_balanced_positions, &TypeBalancer::Rails::BalancedPosition.table_definition
    end
  end

  config.after(:suite) do
    # Clean up database
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  # Include Rails testing helpers
  config.include ActiveJob::TestHelper
  config.include ActiveSupport::Testing::TimeHelpers
end
