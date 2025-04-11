# frozen_string_literal: true

RSpec.describe TypeBalancer::Rails::BalanceCalculationJob do
  let(:post1) { Post.create!(title: "Video 1", media_type: "video") }
  let(:post2) { Post.create!(title: "Image 1", media_type: "image") }
  let(:post3) { Post.create!(title: "Article 1", media_type: "article") }
  let(:scope) { Post.where(id: [post1, post2, post3]) }
  let(:options) { { type_field: "media_type" } }

  describe "#perform" do
    it "creates balanced positions" do
      expect do
        described_class.perform_now(scope, options)
      end.to change { TypeBalancer::Rails::BalancedPosition.count }.by(3)
    end

    it "assigns sequential positions" do
      described_class.perform_now(scope, options)
      positions = TypeBalancer::Rails::BalancedPosition.order(:position).pluck(:position)
      expect(positions).to eq([1, 2, 3])
    end

    it "respects type order" do
      options[:type_order] = [:article, :video, :image]
      described_class.perform_now(scope, options)
      
      records = TypeBalancer::Rails::BalancedPosition.order(:position).map(&:record)
      expect(records.map(&:media_type)).to eq(%w[article video image])
    end

    it "uses transaction for atomic updates" do
      allow(TypeBalancer::Rails::BalancedPosition).to receive(:create!).and_raise("Test error")

      expect do
        described_class.perform_now(scope, options)
      end.to raise_error("Test error")

      expect(TypeBalancer::Rails::BalancedPosition.count).to eq(0)
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
    it "generates consistent cache keys" do
      job = described_class.new
      key1 = job.send(:generate_cache_key, scope, options)
      key2 = job.send(:generate_cache_key, scope, options)

      expect(key1).to eq(key2)
    end

    it "includes scope information in cache key" do
      job = described_class.new
      key = job.send(:generate_cache_key, scope, options)

      expect(key).to include("posts")
      expect(key).to include(scope.cache_key_with_version)
    end

    it "includes options in cache key" do
      job = described_class.new
      key = job.send(:generate_cache_key, scope, options)

      expect(key).to include(Digest::MD5.hexdigest(options.to_json))
    end
  end
end 