require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  fixtures :posts

  before do
    Rails.cache.clear
    allow(TypeBalancer).to receive(:balance).and_call_original
  end

  describe 'GET #index' do
    it 'caches the balanced ID list and reuses it' do
      # First call: should invoke the balancer
      get :index
      expect(TypeBalancer).to have_received(:balance).once
      first_result = assigns(:posts).map(&:id)

      # Second call: should use the cache, not call balancer again
      get :index
      expect(TypeBalancer).to have_received(:balance).once
      second_result = assigns(:posts).map(&:id)
      expect(second_result).to eq(first_result)
    end

    it 'resets the cache when requested via controller param' do
      # Prime the cache
      get :index
      expect(TypeBalancer).to have_received(:balance).once
      first_result = assigns(:posts).map(&:id)

      # Simulate cache reset by passing param (assuming controller supports it)
      allow(TypeBalancer).to receive(:balance).and_call_original # reset spy
      get :index, params: { cache_reset: true }
      expect(TypeBalancer).to have_received(:balance).once
      second_result = assigns(:posts).map(&:id)
      expect(second_result).to eq(first_result) # Should still be balanced, but balancer called again
    end

    it 'isolates cache by type field' do
      get :index, params: { type_field: 'media_type' }
      expect(TypeBalancer).to have_received(:balance).once
      allow(TypeBalancer).to receive(:balance).and_call_original # reset spy
      get :index, params: { type_field: 'other_type' }
      expect(TypeBalancer).to have_received(:balance).once
    end

    it 'respects per-request expires_in option' do
      get :index, params: { expires_in: 1 }
      expect(TypeBalancer).to have_received(:balance).once
      sleep 2
      allow(TypeBalancer).to receive(:balance).and_call_original # reset spy
      get :index, params: { expires_in: 1 }
      expect(TypeBalancer).to have_received(:balance).once
    end

    it 'expires cache and calls balancer again after expiry' do
      get :index, params: { expires_in: 1 }
      expect(TypeBalancer).to have_received(:balance).once
      sleep 2
      allow(TypeBalancer).to receive(:balance).and_call_original # reset spy
      get :index, params: { expires_in: 1 }
      expect(TypeBalancer).to have_received(:balance).once
    end
  end
end
