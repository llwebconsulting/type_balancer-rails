# frozen_string_literal: true

RSpec.describe TypeBalancer::Rails::BalancedCollectionQuery do
  let(:post1) { Post.create!(title: "Video 1", media_type: "video") }
  let(:post2) { Post.create!(title: "Image 1", media_type: "image") }
  let(:post3) { Post.create!(title: "Article 1", media_type: "article") }
  let(:post4) { Post.create!(title: "Video 2", media_type: "video") }
  let(:post5) { Post.create!(title: "Image 2", media_type: "image") }
  let(:post6) { Post.create!(title: "Article 2", media_type: "article") }

  before do
    [post1, post2, post3, post4, post5, post6]
  end

  describe "#initialize" do
    it "infers type field from common field names" do
      query = described_class.new(Post.all)
      expect(query.options[:type_field]).to eq("media_type")
    end

    it "uses provided type field" do
      query = described_class.new(Post.all, field: :category)
      expect(query.options[:type_field]).to eq(:category)
    end

    it "accepts custom type order" do
      order = [:video, :image, :article]
      query = described_class.new(Post.all, order: order)
      expect(query.options[:type_order]).to eq(order)
    end
  end

  describe "#page" do
    let(:query) { described_class.new(Post.all) }

    it "returns balanced results for first page" do
      results = query.page(1)
      expect(results.map(&:media_type)).to eq(%w[video image article video image article])
    end

    it "maintains balance across pages" do
      query.per(3)
      page1 = query.page(1)
      page2 = query.page(2)

      expect(page1.map(&:media_type)).to eq(%w[video image article])
      expect(page2.map(&:media_type)).to eq(%w[video image article])
    end

    it "respects custom type order" do
      order = [:article, :image, :video]
      results = described_class.new(Post.all, order: order).page(1)
      expect(results.map(&:media_type)).to eq(%w[article image video article image video])
    end
  end

  describe "#per" do
    let(:query) { described_class.new(Post.all) }

    it "limits results per page" do
      results = query.per(3).page(1)
      expect(results.size).to eq(3)
    end

    it "respects max_per_page configuration" do
      TypeBalancer::Rails.configuration.max_per_page = 2
      results = query.per(3).page(1)
      expect(results.size).to eq(2)
    end
  end

  describe "caching" do
    let(:query) { described_class.new(Post.all) }

    it "caches balanced positions" do
      expect do
        2.times { query.page(1) }
      end.to change { TypeBalancer::Rails::BalancedPosition.count }.by(6)
    end

    it "invalidates cache when records change" do
      query.page(1)
      post1.touch

      expect do
        query.page(1)
      end.to change { TypeBalancer::Rails::BalancedPosition.count }.by(6)
    end
  end

  describe "background processing" do
    before do
      TypeBalancer::Rails.configuration.async_threshold = 5
    end

    it "processes large collections in background" do
      query = described_class.new(Post.all)
      
      expect do
        query.page(1)
      end.to have_enqueued_job(TypeBalancer::Rails::BalanceCalculationJob)
    end

    it "processes small collections immediately" do
      query = described_class.new(Post.where(id: [post1, post2, post3]))
      
      expect do
        query.page(1)
      end.not_to have_enqueued_job(TypeBalancer::Rails::BalanceCalculationJob)
    end
  end
end 