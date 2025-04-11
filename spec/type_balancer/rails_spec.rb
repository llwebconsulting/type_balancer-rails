# frozen_string_literal: true

require "spec_helper"

RSpec.describe TypeBalancer::Rails do
  it "has a version number" do
    expect(TypeBalancer::Rails::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end

  describe ".configure" do
    after do
      described_class::Container.reset!
      described_class::StrategyRegistry.reset!
    end

    it "yields configuration object" do
      expect { |b| described_class.configure(&b) }
        .to yield_with_args(instance_of(described_class::Configuration))
    end

    it "registers default services" do
      described_class.configure do |config|
        config.storage_strategy = :cursor
        config.cursor_buffer_multiplier = 5
      end

      strategy = described_class.storage_strategy
      expect(strategy).to be_instance_of(described_class::Strategies::CursorStrategy)
      expect(strategy.instance_variable_get(:@buffer_multiplier)).to eq(5)
    end

    it "configures redis strategy with custom client" do
      redis = Redis.new
      described_class.configure do |config|
        config.storage_strategy = :redis
        config.redis = redis
        config.redis_ttl = 2.hours
      end

      strategy = described_class.storage_strategy
      expect(strategy).to be_instance_of(described_class::Strategies::RedisStrategy)
      expect(strategy.instance_variable_get(:@redis)).to eq(redis)
      expect(strategy.instance_variable_get(:@ttl)).to eq(2.hours)
    end
  end

  describe ".storage_strategy" do
    after do
      described_class::Container.reset!
      described_class::StrategyRegistry.reset!
    end

    it "uses cursor strategy by default" do
      described_class.configure { |config| }
      expect(described_class.storage_strategy)
        .to be_instance_of(described_class::Strategies::CursorStrategy)
    end

    it "resolves strategy from container" do
      dummy_strategy = double("DummyStrategy")
      described_class::Container.register(:storage_strategy) { dummy_strategy }
      
      expect(described_class.storage_strategy).to eq(dummy_strategy)
    end
  end

  describe "custom strategy registration" do
    let(:custom_strategy_class) do
      Class.new(described_class::Strategies::BaseStrategy) do
        def initialize(options = {})
          @options = options
        end

        def fetch_page(scope, page_size: 20, cursor: nil)
          [[], nil]
        end

        def next_page_token(result)
          nil
        end
      end
    end

    before do
      described_class::StrategyRegistry.register(:custom, custom_strategy_class)
    end

    after do
      described_class::Container.reset!
      described_class::StrategyRegistry.reset!
    end

    it "allows using custom strategies" do
      described_class.configure do |config|
        config.storage_strategy = :custom
      end

      expect(described_class.storage_strategy)
        .to be_instance_of(custom_strategy_class)
    end
  end
end
