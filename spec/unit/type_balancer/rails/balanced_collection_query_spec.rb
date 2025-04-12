# frozen_string_literal: true

require "unit_helper"

RSpec.describe TypeBalancer::Rails::BalancedCollectionQuery do
  let(:post_class) do
    Class.new do
      def self.name
        "Post"
      end

      def self.all
        []
      end
    end
  end

  let(:posts) do
    [
      instance_double("Post", id: 1, title: "Video 1", media_type: "video", cache_key_with_version: "posts/1-123"),
      instance_double("Post", id: 2, title: "Image 1", media_type: "image", cache_key_with_version: "posts/2-123"),
      instance_double("Post", id: 3, title: "Article 1", media_type: "article", cache_key_with_version: "posts/3-123"),
      instance_double("Post", id: 4, title: "Video 2", media_type: "video", cache_key_with_version: "posts/4-123"),
      instance_double("Post", id: 5, title: "Image 2", media_type: "image", cache_key_with_version: "posts/5-123"),
      instance_double("Post", id: 6, title: "Article 2", media_type: "article", cache_key_with_version: "posts/6-123")
    ]
  end

  let(:scope) do
    relation = instance_double("ActiveRecord::Relation")
    allow(relation).to receive(:model_name).and_return(ActiveModel::Name.new(post_class))
    allow(relation).to receive(:cache_key_with_version).and_return("posts/all-123")
    allow(relation).to receive(:where).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:to_a).and_return(posts)
    allow(relation).to receive(:count).and_return(posts.length)
    relation
  end

  before do
    allow(post_class).to receive(:all).and_return(scope)
  end

  describe "#initialize" do
    it "infers type field from common field names" do
      query = described_class.new(scope)
      expect(query.options[:type_field]).to eq("media_type")
    end

    it "uses provided type field" do
      query = described_class.new(scope, field: :category)
      expect(query.options[:type_field]).to eq(:category)
    end

    it "accepts custom type order" do
      order = [:video, :image, :article]
      query = described_class.new(scope, order: order)
      expect(query.options[:type_order]).to eq(order)
    end
  end

  describe "#page" do
    let(:query) { described_class.new(scope) }

    before do
      allow(Rails.cache).to receive(:fetch).and_yield
    end

    it "returns balanced results for first page" do
      results = query.page(1)
      expect(results.map(&:media_type)).to eq(%w[video image article video image article])
    end

    it "maintains balance across pages" do
      allow(query).to receive(:per_page).and_return(3)
      
      page1 = query.page(1)
      page2 = query.page(2)

      expect(page1.map(&:media_type)).to eq(%w[video image article])
      expect(page2.map(&:media_type)).to eq(%w[video image article])
    end

    it "respects custom type order" do
      order = [:article, :image, :video]
      results = described_class.new(scope, order: order).page(1)
      expect(results.map(&:media_type)).to eq(%w[article image video article image video])
    end
  end

  describe "#per" do
    let(:query) { described_class.new(scope) }

    before do
      allow(Rails.cache).to receive(:fetch).and_yield
    end

    it "limits results per page" do
      allow(query).to receive(:per_page).and_return(3)
      results = query.per(3).page(1)
      expect(results.size).to eq(3)
    end

    it "respects max_per_page configuration" do
      allow(TypeBalancer::Rails.configuration).to receive(:max_per_page).and_return(2)
      allow(query).to receive(:per_page).and_return(2)
      results = query.per(3).page(1)
      expect(results.size).to eq(2)
    end
  end

  describe "caching" do
    let(:query) { described_class.new(scope) }
    let(:cache_key) { "type_balancer/posts/posts/all-123/options-hash" }

    it "uses Rails cache" do
      expect(Rails.cache).to receive(:fetch)
        .with(cache_key, expires_in: 1.hour)
        .and_return(posts)

      query.page(1)
    end

    it "invalidates cache when records change" do
      expect(Rails.cache).to receive(:fetch)
        .with(cache_key, expires_in: 1.hour)
        .twice
        .and_return(posts)

      query.page(1)
      query.page(1)
    end
  end

  describe "background processing" do
    let(:query) { described_class.new(scope) }

    before do
      allow(TypeBalancer::Rails.configuration).to receive(:async_threshold).and_return(5)
    end

    it "processes large collections in background" do
      expect do
        query.page(1)
      end.to have_enqueued_job(TypeBalancer::Rails::BalanceCalculationJob)
    end

    it "processes small collections immediately" do
      small_scope = instance_double("ActiveRecord::Relation")
      allow(small_scope).to receive(:count).and_return(3)
      allow(small_scope).to receive(:model_name).and_return(ActiveModel::Name.new(post_class))
      allow(small_scope).to receive(:cache_key_with_version).and_return("posts/small-123")

      small_query = described_class.new(small_scope)

      expect do
        small_query.page(1)
      end.not_to have_enqueued_job(TypeBalancer::Rails::BalanceCalculationJob)
    end
  end
end 