# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Storage::CursorStorage do
  subject(:storage) { described_class.new }

  describe '#store' do
    let(:key) { 'test_key' }
    let(:value) { { test: 'value' } }

    it 'stores the value' do
      storage.store(key, value)
      expect(storage.fetch(key)).to eq(value)
    end

    context 'with TTL' do
      let(:ttl) { 1 }

      it 'expires after TTL' do
        storage.store(key, value, ttl)
        expect(storage.fetch(key)).to eq(value)

        sleep(1.1) # Wait for TTL to expire
        expect(storage.fetch(key)).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'validates key' do
        expect { storage.store(nil, value) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end

      it 'validates value' do
        expect { storage.store(key, nil) }.to raise_error(ArgumentError, 'Value cannot be nil')
      end

      it 'validates ttl' do
        expect { storage.store(key, value, -1) }.to raise_error(ArgumentError, 'TTL must be a positive integer')
      end
    end

    context 'with symbol key' do
      let(:key) { :test_key }

      it 'converts key to string' do
        storage.store(key, value)
        expect(storage.fetch('test_key')).to eq(value)
      end
    end
  end

  describe '#fetch' do
    let(:key) { 'test_key' }
    let(:value) { { test: 'value' } }

    context 'when key exists' do
      before { storage.store(key, value) }

      it 'returns the value' do
        expect(storage.fetch(key)).to eq(value)
      end
    end

    context 'when key does not exist' do
      it 'returns nil' do
        expect(storage.fetch(key)).to be_nil
      end
    end

    context 'with expired key' do
      before { storage.store(key, value, 1) }

      it 'returns nil after expiration' do
        expect(storage.fetch(key)).to eq(value)
        sleep(1.1) # Wait for TTL to expire
        expect(storage.fetch(key)).to be_nil
      end
    end
  end

  describe '#delete' do
    let(:key) { 'test_key' }
    let(:value) { { test: 'value' } }

    before { storage.store(key, value) }

    it 'removes the value' do
      storage.delete(key)
      expect(storage.fetch(key)).to be_nil
    end

    context 'with TTL' do
      before { storage.store(key, value, 3600) }

      it 'removes TTL information' do
        storage.delete(key)
        expect(storage.instance_variable_get(:@ttl_store)).not_to have_key(key)
      end
    end
  end

  describe '#clear' do
    before do
      storage.store('key1', 'value1')
      storage.store('key2', 'value2', 3600)
    end

    it 'removes all values' do
      storage.clear
      expect(storage.fetch('key1')).to be_nil
      expect(storage.fetch('key2')).to be_nil
    end

    it 'clears TTL information' do
      storage.clear
      expect(storage.instance_variable_get(:@ttl_store)).to be_empty
    end
  end

  describe 'thread safety' do
    let(:threads) { [] }
    let(:keys) { (1..100).map(&:to_s) }

    after { threads.each(&:join) }

    it 'handles concurrent access' do
      # Writer threads
      3.times do
        threads << Thread.new do
          keys.each do |key|
            storage.store(key, "value_#{key}")
          end
        end
      end

      # Reader threads
      3.times do
        threads << Thread.new do
          keys.each do |key|
            storage.fetch(key)
          end
        end
      end

      # Deleter threads
      3.times do
        threads << Thread.new do
          keys.each do |key|
            storage.delete(key)
          end
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end
  end
end 