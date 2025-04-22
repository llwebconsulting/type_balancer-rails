# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TypeBalancerChannel, type: :channel do
  let(:collection) { 'test_collection' }
  let(:stream_name) { "type_balancer_#{collection}" }
  let(:cursor_position) { 42 }

  before do
    stub_connection
  end

  describe '#subscribed' do
    context 'with valid collection' do
      before { subscribe(collection: collection) }

      it 'subscribes to the stream' do
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from(stream_name)
      end
    end

    context 'with blank collection' do
      before { subscribe(collection: '') }

      it 'rejects the subscription' do
        expect(subscription).to be_rejected
      end
    end
  end

  describe '#update_cursor' do
    before { subscribe(collection: collection) }

    it 'broadcasts cursor update message' do
      expect do
        perform :update_cursor, cursor_position: cursor_position
      end.to have_broadcasted_to(stream_name).with(
        action: 'update_cursor',
        cursor_position: cursor_position,
        collection: collection
      )
    end
  end

  describe 'multiple subscribers' do
    before do
      subscribe(collection: collection)
      @second_subscription = subscribe(collection: collection)
    end

    it 'broadcasts to all subscribers' do
      expect do
        perform :update_cursor, cursor_position: cursor_position
      end.to have_broadcasted_to(stream_name).with(
        action: 'update_cursor',
        cursor_position: cursor_position,
        collection: collection
      )

      expect(@second_subscription).to be_confirmed
      expect(@second_subscription.streams).to include(stream_name)
    end
  end

  describe '#method_missing' do
    before { subscribe(collection: collection) }

    it 'broadcasts custom action with cursor position' do
      expect do
        perform :custom_action, cursor_position: cursor_position
      end.to have_broadcasted_to(stream_name).with(
        action: 'custom_action',
        cursor_position: cursor_position,
        collection: collection
      )
    end
  end
end
