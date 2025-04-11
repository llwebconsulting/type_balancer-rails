require "spec_helper"

RSpec.describe TypeBalancer::Rails::Container do
  describe ".register" do
    after { described_class.reset! }

    it "registers a value" do
      described_class.register(:test, "value")
      expect(described_class.resolve(:test)).to eq("value")
    end

    it "registers a block" do
      counter = 0
      described_class.register(:counter) { counter += 1 }
      
      expect(described_class.resolve(:counter)).to eq(1)
      expect(described_class.resolve(:counter)).to eq(2)
    end

    it "allows overwriting existing registrations" do
      described_class.register(:test, "old")
      described_class.register(:test, "new")
      expect(described_class.resolve(:test)).to eq("new")
    end
  end

  describe ".resolve" do
    it "raises KeyError for unregistered services" do
      expect {
        described_class.resolve(:nonexistent)
      }.to raise_error(KeyError, "Service not registered: nonexistent")
    end

    it "resolves dependencies on demand" do
      called = false
      described_class.register(:lazy) { called = true; "value" }
      
      expect(called).to be false
      described_class.resolve(:lazy)
      expect(called).to be true
    end
  end

  describe ".reset!" do
    it "clears all registrations" do
      described_class.register(:test, "value")
      described_class.reset!
      
      expect {
        described_class.resolve(:test)
      }.to raise_error(KeyError)
    end
  end
end 