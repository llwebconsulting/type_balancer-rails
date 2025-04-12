# frozen_string_literal: true

require "unit_helper"

RSpec.describe TypeBalancer::Rails::BalanceCalculationJob do
  let(:post_class) do
    Class.new do
      def self.name
        "Post"
      end

      def self.table_name
        "posts"
      end
    end
  end

  let(:posts) do
    [
      instance_double("Post", id: 1, title: "Video 1", media_type: "video", cache_key_with_version: "posts/1-123"),
      instance_double("Post", id: 2, title: "Image 1", media_type: "image", cache_key_with_version: "posts/2-123"),
      instance_double("Post", id: 3, title: "Article 1", media_type: "article", cache_key_with_version: "posts/3-123")
    ]
  end

  let(:scope) do
    relation = instance_double("ActiveRecord::Relation")
    allow(relation).to receive(:model_name).and_return(ActiveModel::Name.new(post_class))
    allow(relation).to receive(:cache_key_with_version).and_return("posts/all-123")
    allow(relation).to receive(:to_a).and_return(posts)
    relation
  end

  let(:options) { { type_field: "media_type" } }
  let(:cache_key) { "type_balancer/posts/posts/all-123/options-hash" }

  describe "#perform" do
    let(:balanced_position_class) { class_double("TypeBalancer::Rails::BalancedPosition").as_stubbed_const }
    let(:balanced_positions) { [] }

    before do
      allow(balanced_position_class).to receive(:transaction).and_yield
      allow(balanced_position_class).to receive(:create!) do |attrs|
        position = instance_double("TypeBalancer::Rails::BalancedPosition", 
          record: attrs[:record],
          position: attrs[:position],
          cache_key: attrs[:cache_key]
        )
        balanced_positions << position
        position
      end
    end

    it "creates balanced positions" do
      expect do
        described_class.perform_now(scope, options)
      end.to change { balanced_positions.count }.by(3)
    end

    it "assigns sequential positions" do
      described_class.perform_now(scope, options)
      positions = balanced_positions.map(&:position)
      expect(positions).to eq([1, 2, 3])
    end

    it "respects type order" do
      options[:type_order] = [:article, :video, :image]
      described_class.perform_now(scope, options)
      
      records = balanced_positions.map(&:record)
      expect(records.map(&:media_type)).to eq(%w[article video image])
    end

    it "uses transaction for atomic updates" do
      allow(balanced_position_class).to receive(:create!).and_raise("Test error")

      expect do
        described_class.perform_now(scope, options)
      end.to raise_error("Test error")

      expect(balanced_positions).to be_empty
    end

    it "broadcasts completion" do
      expect do
        described_class.perform_now(scope, options)
      end.to have_broadcasted_to("type_balancer_posts").with(
        status: "completed"
      )
    end
  end

  describe "cache key generation" do
    let(:job) { described_class.new }

    before do
      allow(scope).to receive(:cache_key_with_version).and_return("posts/all-123")
      allow(scope).to receive(:model_name).and_return(ActiveModel::Name.new(post_class))
    end

    it "generates consistent cache keys" do
      key1 = job.send(:generate_cache_key, scope, options)
      key2 = job.send(:generate_cache_key, scope, options)

      expect(key1).to eq(key2)
    end

    it "includes scope information in cache key" do
      key = job.send(:generate_cache_key, scope, options)

      expect(key).to include("posts")
      expect(key).to include("posts/all-123")
    end

    it "includes options in cache key" do
      key = job.send(:generate_cache_key, scope, options)

      expect(key).to include(Digest::MD5.hexdigest(options.to_json))
    end
  end
end 