# frozen_string_literal: true

require "unit_helper"

RSpec.describe TypeBalancer::Rails::Strategies::BaseStrategy do
  let(:collection) { double("collection") }
  let(:options) { { page_size: 10 } }
  let(:strategy) { described_class.new(collection, options) }

  describe "#initialize" do
    it "accepts a collection and options" do
      expect { strategy }.not_to raise_error
    end

    it "works with default options" do
      expect { described_class.new(collection) }.not_to raise_error
    end
  end

  describe "#execute" do
    it "raises NotImplementedError" do
      expect { strategy.execute }.to raise_error(NotImplementedError, "#{described_class} must implement #execute")
    end
  end
end 