# frozen_string_literal: true

RSpec.describe TypeBalancer::Rails::CacheInvalidation do
  let(:post) { Post.create!(title: "Test Post", media_type: "video") }
  let(:cache_key) { "type_balancer/posts/#{post.cache_key_with_version}" }

  before do
    TypeBalancer::Rails::BalancedPosition.create!(
      record: post,
      position: 1,
      cache_key: cache_key
    )
  end

  describe "after_commit callback" do
    it "invalidates cache when record is updated" do
      expect do
        post.update!(title: "Updated Post")
      end.to change { TypeBalancer::Rails::BalancedPosition.count }.by(-1)
    end

    it "invalidates cache when record is destroyed" do
      expect do
        post.destroy
      end.to change { TypeBalancer::Rails::BalancedPosition.count }.by(-1)
    end

    it "cleans up all positions for the record" do
      other_key = "type_balancer/posts/other_key"
      TypeBalancer::Rails::BalancedPosition.create!(
        record: post,
        position: 2,
        cache_key: other_key
      )

      expect do
        post.touch
      end.to change { TypeBalancer::Rails::BalancedPosition.count }.by(-2)
    end
  end

  describe "cache key generation" do
    it "includes model name in cache key" do
      expect(cache_key).to include("posts")
    end

    it "includes record version in cache key" do
      expect(cache_key).to include(post.cache_key_with_version)
    end
  end
end 