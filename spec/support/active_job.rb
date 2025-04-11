# frozen_string_literal: true

require 'active_job'

ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|
  config.include ActiveJob::TestHelper
  
  config.before(:each) do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end 