# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancerChannel, type: :channel do
  include ActionCable::TestHelper
  include RedisHelper

  let(:collection_name) { 'posts' }
  let(:redis_client) { mock_redis }

  before do
    # Enable debug logging
    Rails.logger.level = :debug
    ActionCable.server.config.logger.level = :debug

    # Configure TypeBalancer with MockRedis
    with_mocked_redis do
      TypeBalancer::Rails.configure do |config|
        config.enable_redis
        config.redis_client = redis_client
        config.max_per_page = 100
        config.cursor_buffer_multiplier = 2
      end
    end
  end

  describe 'channel setup' do
    it 'successfully subscribes to the channel' do
      subscribe(collection: collection_name)
      expect(subscription).to be_confirmed
      expect(subscription.streams).to include("type_balancer_#{collection_name}")
    end

    it 'unsubscribes and stops streaming' do
      subscribe(collection: collection_name)
      expect(subscription.streams).to include("type_balancer_#{collection_name}")

      unsubscribe
      expect(subscription.streams).to be_empty
    end

    context 'with invalid parameters' do
      it 'rejects subscription without collection parameter' do
        subscribe
        expect(subscription).to be_rejected
      end

      it 'rejects subscription with empty collection parameter' do
        subscribe(collection: '')
        expect(subscription).to be_rejected
      end

      it 'rejects subscription with nil collection parameter' do
        subscribe(collection: nil)
        expect(subscription).to be_rejected
      end
    end
  end

  describe 'cursor position broadcasting' do
    let(:cursor_position) { 42 }

    before do
      subscribe(collection: collection_name)
    end

    it 'broadcasts cursor position updates' do
      expect do
        perform :update_cursor, cursor_position: cursor_position
      end.to have_broadcasted_to("type_balancer_#{collection_name}")
        .with(
          action: 'update_cursor',
          cursor_position: cursor_position,
          collection: collection_name
        )
    end

    it 'handles string cursor positions' do
      expect do
        perform :update_cursor, cursor_position: '42'
      end.to have_broadcasted_to("type_balancer_#{collection_name}")
        .with(
          action: 'update_cursor',
          cursor_position: '42',
          collection: collection_name
        )
    end

    it 'handles nil cursor position' do
      expect do
        perform :update_cursor, cursor_position: nil
      end.to have_broadcasted_to("type_balancer_#{collection_name}")
        .with(
          action: 'update_cursor',
          cursor_position: nil,
          collection: collection_name
        )
    end

    it 'handles missing cursor position' do
      expect do
        perform :update_cursor
      end.to have_broadcasted_to("type_balancer_#{collection_name}")
        .with(
          action: 'update_cursor',
          cursor_position: nil,
          collection: collection_name
        )
    end
  end

  describe 'multiple subscribers' do
    let(:cursor_position) { 42 }

    before do
      subscribe(collection: collection_name)
      @second_subscription = subscribe(collection: collection_name)
    end

    it 'broadcasts to all subscribers' do
      expect do
        perform :update_cursor, cursor_position: cursor_position
      end.to have_broadcasted_to("type_balancer_#{collection_name}")
        .with(
          action: 'update_cursor',
          cursor_position: cursor_position,
          collection: collection_name
        )

      expect(@second_subscription).to be_confirmed
      expect(@second_subscription.streams).to include("type_balancer_#{collection_name}")
    end

    it 'handles updates from different subscribers' do
      expect do
        perform :update_cursor, cursor_position: 42
        perform :update_cursor, cursor_position: 43
      end.to have_broadcasted_to("type_balancer_#{collection_name}")
        .exactly(:twice)
    end
  end

  describe 'error handling' do
    before do
      subscribe(collection: collection_name)
    end

    it 'handles unknown action types' do
      cursor_position = 42
      data = { cursor_position: cursor_position, action: 'unknown_action' }

      expect do
        perform :unknown_action, data
      end.to have_broadcasted_to("type_balancer_#{collection_name}").with(
        action: 'unknown_action',
        cursor_position: cursor_position,
        collection: collection_name
      )
    end

    it 'handles malformed messages' do
      expect do
        perform :receive, {}
      end.to have_broadcasted_to("type_balancer_#{collection_name}")
        .with(
          action: 'receive',
          cursor_position: nil,
          collection: collection_name
        )
    end

    it 'handles empty messages' do
      expect do
        perform :receive, {}
      end.to have_broadcasted_to("type_balancer_#{collection_name}")
        .with(
          action: 'receive',
          cursor_position: nil,
          collection: collection_name
        )
    end
  end
end
