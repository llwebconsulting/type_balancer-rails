# frozen_string_literal: true

RSpec.describe TypeBalancer::Rails::BalancedPosition do
  let(:post) { Post.create!(title: "Test Post", media_type: "video") }
  let(:cache_key) { "test_cache_key" }

  describe "validations" do
    subject(:position) do
      described_class.new(
        record: post,
        position: 1,
        cache_key: cache_key,
        type_field: "media_type"
      )
    end

    it "is valid with valid attributes" do
      expect(position).to be_valid
    end

    it "requires a record" do
      position.record = nil
      expect(position).not_to be_valid
    end

    it "requires a position" do
      position.position = nil
      expect(position).not_to be_valid
    end

    it "requires a cache_key" do
      position.cache_key = nil
      expect(position).not_to be_valid
    end

    it "enforces unique position within cache_key" do
      position.save!
      duplicate = described_class.new(
        record: Post.create!(title: "Another Post", media_type: "image"),
        position: 1,
        cache_key: cache_key
      )
      expect(duplicate).not_to be_valid
    end

    it "enforces unique record within cache_key" do
      position.save!
      duplicate = described_class.new(
        record: post,
        position: 2,
        cache_key: cache_key
      )
      expect(duplicate).not_to be_valid
    end
  end

  describe ".for_collection" do
    before do
      3.times do |i|
        described_class.create!(
          record: Post.create!(title: "Post #{i}", media_type: "video"),
          position: i + 1,
          cache_key: cache_key
        )
      end
    end

    it "returns positions for a cache key in order" do
      positions = described_class.for_collection(cache_key)
      expect(positions.map(&:position)).to eq([1, 2, 3])
    end

    it "excludes positions from other cache keys" do
      other_key = "other_cache_key"
      described_class.create!(
        record: Post.create!(title: "Other Post", media_type: "video"),
        position: 1,
        cache_key: other_key
      )

      positions = described_class.for_collection(cache_key)
      expect(positions.count).to eq(3)
    end
  end

  describe ".table_definition" do
    it "returns a valid table definition" do
      definition = described_class.table_definition
      expect(definition).to be_a(Proc)
    end
  end
end 