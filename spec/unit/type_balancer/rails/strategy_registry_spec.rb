# frozen_string_literal: true

require "unit_helper"

RSpec.describe TypeBalancer::Rails::StrategyRegistry do
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

  let(:scope) do
    relation = instance_double("ActiveRecord::Relation")
    allow(relation).to receive(:model_name).and_return(ActiveModel::Name.new(post_class))
    allow(relation).to receive(:cache_key_with_version).and_return("posts/all-123")
    relation
  end

  let(:dummy_strategy) do
    Class.new(TypeBalancer::Rails::Strategies::BaseStrategy) do
      def fetch_page(scope, page_size: 20, cursor: nil)
        posts = [
          instance_double("Post", id: 1, media_type: "video"),
          instance_double("Post", id: 2, media_type: "image")
        ]
        [posts, "next_cursor"]
      end

      def next_page_token(result)
        "next_cursor"
      end
    end
  end

  describe ".register" do
    after { described_class.reset! }

    it "registers a strategy class" do
      described_class.register(:test, dummy_strategy)
      expect(described_class.get(:test)).to eq(dummy_strategy)
    end

    it "allows overwriting existing strategies" do
      first_strategy = Class.new(TypeBalancer::Rails::Strategies::BaseStrategy)
      described_class.register(:test, first_strategy)
      described_class.register(:test, dummy_strategy)
      expect(described_class.get(:test)).to eq(dummy_strategy)
    end
  end

  describe ".get" do
    before { described_class.register(:test, dummy_strategy) }
    after { described_class.reset! }

    it "retrieves a registered strategy" do
      expect(described_class.get(:test)).to eq(dummy_strategy)
    end

    it "raises ArgumentError for unknown strategies" do
      expect {
        described_class.get(:nonexistent)
      }.to raise_error(ArgumentError, "Unknown storage strategy: nonexistent")
    end
  end

  describe ".reset!" do
    before do
      # Mock the default strategies to avoid loading actual implementations
      allow(TypeBalancer::Rails::Strategies).to receive(:const_get).with("CursorStrategy")
        .and_return(Class.new(TypeBalancer::Rails::Strategies::BaseStrategy))
      allow(TypeBalancer::Rails::Strategies).to receive(:const_get).with("RedisStrategy")
        .and_return(Class.new(TypeBalancer::Rails::Strategies::BaseStrategy))
    end

    it "clears all registered strategies" do
      described_class.register(:test, dummy_strategy)
      described_class.reset!
      
      expect {
        described_class.get(:test)
      }.to raise_error(ArgumentError)
    end
  end

  describe "default strategies" do
    let(:cursor_strategy) { class_double("TypeBalancer::Rails::Strategies::CursorStrategy") }
    let(:redis_strategy) { class_double("TypeBalancer::Rails::Strategies::RedisStrategy") }

    before do
      stub_const("TypeBalancer::Rails::Strategies::CursorStrategy", cursor_strategy)
      stub_const("TypeBalancer::Rails::Strategies::RedisStrategy", redis_strategy)
      described_class.reset!
    end

    after { described_class.reset! }

    it "registers :cursor strategy by default" do
      expect(described_class.get(:cursor)).to eq(cursor_strategy)
    end

    it "registers :redis strategy by default" do
      expect(described_class.get(:redis)).to eq(redis_strategy)
    end

    it "allows custom strategies to override defaults" do
      described_class.register(:cursor, dummy_strategy)
      expect(described_class.get(:cursor)).to eq(dummy_strategy)
    end
  end
end 