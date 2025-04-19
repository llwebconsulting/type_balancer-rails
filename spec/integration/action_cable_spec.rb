# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActionCable Integration', type: :integration do
  include ActionCable::TestHelper
  include ActiveJob::TestHelper

  let(:collection_name) { 'posts' }
  let(:redis_client) { Redis.new(url: 'redis://localhost:6379/1') }

  before do
    # Configure Redis for both TypeBalancer and ActionCable
    TypeBalancer::Rails.configure do |config|
      config.enable_redis
      config.configure_redis(redis_client)
      config.max_per_page = 100
      config.cursor_buffer_multiplier = 2
    end
  end

  describe 'channel setup' do
    it 'successfully subscribes to the channel' do
      perform_enqueued_jobs do
        subscribe_to_channel
        expect(subscription).to be_confirmed
        expect(subscription.streams).to include("type_balancer_#{collection_name}")
      end
    end

    it 'unsubscribes and stops streaming' do
      perform_enqueued_jobs do
        subscribe_to_channel
        expect(subscription.streams).to include("type_balancer_#{collection_name}")

        unsubscribe_from_channel
        expect(subscription.streams).to be_empty
      end
    end
  end

  describe 'cursor position broadcasting' do
    let(:cursor_position) { 42 }

    it 'broadcasts cursor position updates' do
      perform_enqueued_jobs do
        subscribe_to_channel

        expect do
          subscription.perform('receive', {
                                 'action' => 'update_cursor',
                                 'cursor_position' => cursor_position
                               })
        end.to have_broadcasted_to("type_balancer_#{collection_name}")
          .with(
            action: 'update_cursor',
            cursor_position: cursor_position,
            collection: collection_name
          )
      end
    end
  end

  private

  def subscribe_to_channel
    subscribe(TypeBalancerChannel, collection: collection_name)
  end

  def unsubscribe_from_channel
    subscription.unsubscribe_from_channel
  end
end
