# frozen_string_literal: true

require "unit_helper"
require "type_balancer/rails/container"

RSpec.describe TypeBalancer::Rails::Container do
  # Reset container state before each test
  before { described_class.reset! }
  after { described_class.reset! }

  describe ".register" do
    it "registers a simple value" do
      described_class.register(:test, "value")
      expect(described_class.resolve(:test)).to eq("value")
    end

    it "registers a complex object" do
      service = instance_double("ComplexService", call: "result")
      described_class.register(:service, service)
      expect(described_class.resolve(:service)).to eq(service)
    end

    it "registers a block that returns new instances" do
      counter = 0
      described_class.register(:counter) { counter += 1 }
      
      expect(described_class.resolve(:counter)).to eq(1)
      expect(described_class.resolve(:counter)).to eq(2)
    end

    it "allows overwriting existing registrations" do
      old_service = instance_double("OldService")
      new_service = instance_double("NewService")
      
      described_class.register(:test, old_service)
      described_class.register(:test, new_service)
      
      expect(described_class.resolve(:test)).to eq(new_service)
    end

    it "supports registering nil values" do
      described_class.register(:null_service, nil)
      expect(described_class.resolve(:null_service)).to be_nil
    end
  end

  describe ".resolve" do
    it "raises KeyError for unregistered services" do
      expect {
        described_class.resolve(:nonexistent)
      }.to raise_error(KeyError, "Service not registered: nonexistent")
    end

    it "resolves dependencies on demand" do
      initialization_count = 0
      described_class.register(:lazy) do
        initialization_count += 1
        instance_double("LazyService")
      end
      
      expect(initialization_count).to eq(0)
      described_class.resolve(:lazy)
      expect(initialization_count).to eq(1)
    end

    it "caches block results" do
      initialization_count = 0
      described_class.register(:cached) do
        initialization_count += 1
        instance_double("CachedService")
      end

      2.times { described_class.resolve(:cached) }
      expect(initialization_count).to eq(1)
    end
  end

  describe ".reset!" do
    let(:service) { instance_double("TestService") }

    before do
      described_class.register(:test, service)
      described_class.register(:lazy) { instance_double("LazyService") }
    end

    it "clears all registrations" do
      described_class.reset!
      
      expect {
        described_class.resolve(:test)
      }.to raise_error(KeyError)
      
      expect {
        described_class.resolve(:lazy)
      }.to raise_error(KeyError)
    end

    it "allows re-registration after reset" do
      described_class.reset!
      new_service = instance_double("NewService")
      
      described_class.register(:test, new_service)
      expect(described_class.resolve(:test)).to eq(new_service)
    end
  end
end 