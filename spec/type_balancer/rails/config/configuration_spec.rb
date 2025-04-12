# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Config::Configuration do
  subject(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default values' do
      expect(config.cache_enabled).to be true
      expect(config.cache_ttl).to eq 1.hour
      expect(config.redis_ttl).to eq 1.hour
      expect(config.cursor_buffer_multiplier).to eq 1.5
      expect(config.background_processing_threshold).to eq 1000
      expect(config.max_per_page).to eq 100
    end
  end

  describe '#reset!' do
    it 'resets all values to defaults' do
      config.cache_enabled = false
      config.cache_ttl = 2.hours
      config.redis_ttl = 30.minutes
      config.cursor_buffer_multiplier = 2.0
      config.background_processing_threshold = 500
      config.max_per_page = 50

      config.reset!

      expect(config.cache_enabled).to be true
      expect(config.cache_ttl).to eq 1.hour
      expect(config.redis_ttl).to eq 1.hour
      expect(config.cursor_buffer_multiplier).to eq 1.5
      expect(config.background_processing_threshold).to eq 1000
      expect(config.max_per_page).to eq 100
    end
  end
end 