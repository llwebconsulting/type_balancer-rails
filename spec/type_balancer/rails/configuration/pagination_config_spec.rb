# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Configuration::PaginationConfig do
  subject(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default max_per_page' do
      expect(config.max_per_page).to eq(100)
    end

    context 'with custom values' do
      subject(:config) { described_class.new(max_per_page: 50) }

      it 'sets custom max_per_page' do
        expect(config.max_per_page).to eq(50)
      end
    end
  end

  describe '#set_max_per_page' do
    it 'updates max_per_page' do
      config.set_max_per_page(50)
      expect(config.max_per_page).to eq(50)
    end

    it 'handles string values' do
      config.set_max_per_page('75')
      expect(config.max_per_page).to eq(75)
    end

    it 'ignores invalid values' do
      config.set_max_per_page(0)
      expect(config.max_per_page).to eq(100)

      config.set_max_per_page(-1)
      expect(config.max_per_page).to eq(100)
    end
  end

  describe '#reset!' do
    subject(:config) { described_class.new(max_per_page: 50) }

    it 'resets all values to defaults' do
      config.reset!
      expect(config.max_per_page).to eq(100)
    end
  end
end 