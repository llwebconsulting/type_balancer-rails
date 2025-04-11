require "spec_helper"

RSpec.describe TypeBalancer::Rails::StrategyRegistry do
  let(:dummy_strategy) do
    Class.new(TypeBalancer::Rails::Strategies::BaseStrategy) do
      def fetch_page(scope, page_size: 20, cursor: nil)
        [[], nil]
      end

      def next_page_token(result)
        nil
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
      described_class.register(:test, String)
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
    it "clears all registered strategies" do
      described_class.register(:test, dummy_strategy)
      described_class.reset!
      
      expect {
        described_class.get(:test)
      }.to raise_error(ArgumentError)
    end
  end

  describe "default strategies" do
    after { described_class.reset! }

    it "registers :cursor strategy by default" do
      expect(described_class.get(:cursor))
        .to eq(TypeBalancer::Rails::Strategies::CursorStrategy)
    end

    it "registers :redis strategy by default" do
      expect(described_class.get(:redis))
        .to eq(TypeBalancer::Rails::Strategies::RedisStrategy)
    end
  end
end 