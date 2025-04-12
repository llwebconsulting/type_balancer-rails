# frozen_string_literal: true

require "unit_helper"
require "type_balancer/rails/balanced_collection_query"

RSpec.describe TypeBalancer::Rails::BalancedCollectionQuery do
  let(:post_class) do
    Class.new do
      def self.where(*args)
        @where_args = args
        self
      end

      def self.limit(value)
        @limit_value = value
        self
      end

      def self.offset(value)
        @offset_value = value
        self
      end

      def self.to_a
        # Simulate posts with different media types
        [
          OpenStruct.new(id: 1, media_type: "image"),
          OpenStruct.new(id: 2, media_type: "video"),
          OpenStruct.new(id: 3, media_type: "text")
        ]
      end
    end
  end

  let(:collection) { post_class }
  let(:type_field) { :media_type }
  let(:page) { 1 }
  let(:per_page) { 10 }

  subject(:query) do
    described_class.new(
      collection: collection,
      type_field: type_field,
      page: page,
      per_page: per_page
    )
  end

  describe "#execute" do
    it "returns balanced results" do
      results = query.execute
      types = results.map(&:media_type)
      expect(types.uniq.sort).to eq(["image", "text", "video"])
    end

    context "with caching enabled" do
      before do
        allow(Rails.cache).to receive(:fetch).and_yield
      end

      it "uses the cache" do
        expect(Rails.cache).to receive(:fetch).with(
          "type_balancer/posts/balanced_query/page_1/per_10",
          expires_in: 1.hour
        )
        query.execute
      end
    end
  end

  describe "#background_processing?" do
    context "when collection size is large" do
      before do
        allow(collection).to receive(:count).and_return(1000)
      end

      it "returns true" do
        expect(query.background_processing?).to be true
      end
    end

    context "when collection size is small" do
      before do
        allow(collection).to receive(:count).and_return(10)
      end

      it "returns false" do
        expect(query.background_processing?).to be false
      end
    end
  end
end 