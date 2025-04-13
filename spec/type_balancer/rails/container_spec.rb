# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Container do
  # Reset the container after each test
  after { described_class.reset! }

  describe '.register' do
    it 'registers a value directly' do
      value = double('Service')
      described_class.register(:service, value)
      expect(described_class.resolve(:service)).to eq(value)
    end

    it 'registers a block' do
      value = double('Service')
      described_class.register(:service) { value }
      expect(described_class.resolve(:service)).to eq(value)
    end

    it 'overwrites existing registration' do
      first_value = double('FirstService')
      second_value = double('SecondService')
      
      described_class.register(:service, first_value)
      described_class.register(:service, second_value)
      
      expect(described_class.resolve(:service)).to eq(second_value)
    end

    it 'clears cached value when re-registering' do
      first_value = double('FirstService')
      second_value = double('SecondService')
      
      described_class.register(:service, first_value)
      described_class.resolve(:service) # Cache the first value
      described_class.register(:service, second_value)
      
      expect(described_class.resolve(:service)).to eq(second_value)
    end
  end

  describe '.resolve' do
    context 'with caching enabled' do
      it 'caches the resolved value' do
        counter = 0
        described_class.register(:service) { counter += 1 }

        first_resolve = described_class.resolve(:service)
        second_resolve = described_class.resolve(:service)

        expect(first_resolve).to eq(1)
        expect(second_resolve).to eq(1)
        expect(counter).to eq(1)
      end
    end

    context 'with caching disabled' do
      it 'does not cache the resolved value' do
        counter = 0
        described_class.register(:service, cache: false) { counter += 1 }

        first_resolve = described_class.resolve(:service)
        second_resolve = described_class.resolve(:service)

        expect(first_resolve).to eq(1)
        expect(second_resolve).to eq(2)
        expect(counter).to eq(2)
      end
    end

    context 'with unregistered service' do
      it 'raises KeyError' do
        expect {
          described_class.resolve(:unregistered)
        }.to raise_error(KeyError, 'Service not registered: unregistered')
      end
    end
  end

  describe '.reset!' do
    it 'clears all registrations' do
      service = double('Service')
      described_class.register(:service, service)
      described_class.resolve(:service) # Cache the value

      described_class.reset!

      expect {
        described_class.resolve(:service)
      }.to raise_error(KeyError, 'Service not registered: service')
    end

    it 'clears the cache' do
      counter = 0
      described_class.register(:service) { counter += 1 }
      
      first_resolve = described_class.resolve(:service)
      described_class.reset!
      described_class.register(:service) { counter += 1 }
      second_resolve = described_class.resolve(:service)

      expect(first_resolve).to eq(1)
      expect(second_resolve).to eq(2)
      expect(counter).to eq(2)
    end
  end
end 