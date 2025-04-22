# frozen_string_literal: true

require 'action_cable/testing/rspec'

module ActionCableHelper
  def setup_action_cable
    # Clear any existing configuration
    ActionCable.server.pubsub.shutdown if ActionCable.server.pubsub
    ActionCable.server.config.cable = { 'adapter' => 'test' }
    ActionCable.server.config.disable_request_forgery_protection = true
    ActionCable.server.config.allowed_request_origins = ['http://example.com']
    ActionCable.server.config.url = 'ws://example.com/cable'
    ActionCable.server.config.mount_path = '/cable'
    ActionCable.server.config.logger = Logger.new(nil)
  end
end

RSpec.configure do |config|
  config.include ActionCableHelper
  config.include ActionCable::TestHelper

  config.before(:each, type: [:integration, :channel]) do
    setup_action_cable
  end
end
