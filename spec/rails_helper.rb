# frozen_string_literal: true

require 'spec_helper'
require 'active_record'
require 'active_support'
require 'active_support/test_case'
require 'active_support/testing/time_helpers'
require 'active_job'
require 'action_cable'

# Configure Rails environment
ENV['RAILS_ENV'] = 'test'

# Set up ActiveRecord
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Set up ActiveJob
ActiveJob::Base.queue_adapter = :test

# Set up ActionCable
ActionCable.server = ActionCable::Server::Base.new
ActionCable.server.config.cable = { adapter: 'test' }

RSpec.configure do |config|
  # Include Rails testing helpers
  config.include ActiveSupport::Testing::TimeHelpers

  # Include ActionCable testing helpers
  config.include ActionCable::TestHelper

  # Clean up ActionCable subscriptions
  config.before do
    ActionCable.server.pubsub.reset!
  end

  # Clean up ActiveJob queue
  config.before do
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    ActiveJob::Base.queue_adapter.performed_jobs.clear
  end

  # Clean up database
  config.before do
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
  end

  config.after do
    ActiveRecord::Base.connection.rollback_transaction
  end
end

# Load support files
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].sort.each { |f| require f }
