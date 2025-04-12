# frozen_string_literal: true

require "unit_helper"

RSpec.describe TypeBalancer::Rails::Configuration do
  describe "default values" do
    subject(:config) { described_class.new }

    it "sets default cursor buffer multiplier" do
      expect(config.cursor_buffer_multiplier).to eq(3)
    end

    it "sets default background processing threshold" do
      expect(config.background_processing_threshold).to eq(1000)
    end

    it "enables caching by default" do
      expect(config.cache_enabled).to be true
    end

    it "sets default cache TTL" do
      expect(config.cache_ttl).to eq(1.hour)
    end
  end

  describe ".configure" do
    after { TypeBalancer::Rails.configuration = described_class.new }

    it "allows setting custom values" do
      TypeBalancer::Rails.configure do |config|
        config.cursor_buffer_multiplier = 5
        config.background_processing_threshold = 2000
        config.cache_enabled = false
        config.cache_ttl = 2.hours
      end

      config = TypeBalancer::Rails.configuration
      expect(config.cursor_buffer_multiplier).to eq(5)
      expect(config.background_processing_threshold).to eq(2000)
      expect(config.cache_enabled).to be false
      expect(config.cache_ttl).to eq(2.hours)
    end
  end
end 