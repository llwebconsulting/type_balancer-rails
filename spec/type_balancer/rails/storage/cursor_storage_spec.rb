# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Storage::CursorStorage do
  let(:storage) { described_class.new }
  let(:key) { 'test_key' }
  let(:value) { { data: 'test_value' } }

  # Create a test class that responds to nil? but not to_json
  let(:non_json_class) do
    Class.new do
      undef_method :to_json if method_defined?(:to_json)
      
      def nil?
        false
      end
    end
  end

  describe '#initialize' do
    it 'initializes with empty stores and a mutex' do
      expect(storage.instance_variable_get(:@store)).to eq({})
      expect(storage.instance_variable_get(:@ttl_store)).to eq({})
      expect(storage.instance_variable_get(:@mutex)).to be_a(Mutex)
    end

    it 'accepts options hash' do
      options = { custom: 'option' }
      storage_with_options = described_class.new(options)
      expect(storage_with_options.send(:options)).to eq(options)
    end
  end

  describe '#store' do
    it 'stores a value with a string key' do
      expect(storage.store(key, value)).to eq(value)
      expect(storage.fetch(key)).to eq(value)
    end

    it 'stores a value with a symbol key' do
      symbol_key = :test_key
      expect(storage.store(symbol_key, value)).to eq(value)
      expect(storage.fetch(symbol_key.to_s)).to eq(value)
    end

    it 'stores a value with TTL' do
      ttl = 2
      storage.store(key, value, ttl)
      expect(storage.fetch(key)).to eq(value)
      
      # Simulate time passing
      future_time = Time.now.to_i + ttl + 1
      allow(Time).to receive(:now).and_return(Time.at(future_time))
      
      expect(storage.fetch(key)).to be_nil
    end

    context 'with invalid inputs' do
      it 'raises error for nil key' do
        expect { storage.store(nil, value) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end

      it 'raises error for empty key' do
        expect { storage.store('', value) }.to raise_error(ArgumentError, 'Key cannot be empty')
      end

      it 'raises error for nil value' do
        expect { storage.store(key, nil) }.to raise_error(ArgumentError, 'Value cannot be nil')
      end

      it 'raises error for value not responding to to_json' do
        invalid_value = non_json_class.new
        expect(invalid_value.respond_to?(:to_json)).to be false
        expect { storage.store(key, invalid_value) }.to raise_error(ArgumentError, 'Value must respond to to_json')
      end

      it 'raises error for negative TTL' do
        expect { storage.store(key, value, -1) }.to raise_error(ArgumentError, 'TTL must be a non-negative integer')
      end
    end
  end

  describe '#fetch' do
    before { storage.store(key, value) }

    it 'retrieves a stored value' do
      expect(storage.fetch(key)).to eq(value)
    end

    it 'returns nil for non-existent key' do
      expect(storage.fetch('non_existent')).to be_nil
    end

    it 'raises error for invalid key' do
      expect { storage.fetch(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
    end
  end

  describe '#delete' do
    before { storage.store(key, value) }

    it 'removes a stored value' do
      expect(storage.delete(key)).to eq(key)
      expect(storage.fetch(key)).to be_nil
    end

    it 'removes TTL information' do
      storage.store(key, value, 60)
      storage.delete(key)
      expect(storage.instance_variable_get(:@ttl_store)[key]).to be_nil
    end

    it 'returns nil for non-existent key' do
      expect(storage.delete('non_existent')).to eq('non_existent')
    end

    it 'raises error for invalid key' do
      expect { storage.delete(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
    end
  end

  describe '#clear' do
    before do
      storage.store(key, value)
      storage.store('another_key', { data: 'another_value' }, 60)
    end

    it 'removes all stored values' do
      storage.clear
      expect(storage.fetch(key)).to be_nil
      expect(storage.fetch('another_key')).to be_nil
    end

    it 'clears TTL information' do
      storage.clear
      expect(storage.instance_variable_get(:@ttl_store)).to be_empty
    end
  end

  describe 'thread safety' do
    it 'handles concurrent access' do
      threads = []
      keys = (1..10).map { |i| "key_#{i}" }
      
      10.times do |i|
        threads << Thread.new do
          storage.store(keys[i], { data: "value_#{i}" })
          sleep(0.1)
          storage.fetch(keys[i])
          storage.delete(keys[i])
        end
      end

      threads.each(&:join)
      expect(storage.instance_variable_get(:@store)).to be_empty
    end
  end

  describe 'expired key cleanup' do
    it 'automatically removes expired keys during fetch' do
      storage.store(key, value, 1)
      
      # Simulate time passing
      future_time = Time.now.to_i + 2
      allow(Time).to receive(:now).and_return(Time.at(future_time))
      
      expect(storage.fetch(key)).to be_nil
      expect(storage.instance_variable_get(:@ttl_store)[key]).to be_nil
    end

    it 'automatically removes expired keys during store' do
      storage.store('expired_key', { data: 'old' }, 1)
      
      # Simulate time passing
      future_time = Time.now.to_i + 2
      allow(Time).to receive(:now).and_return(Time.at(future_time))
      
      storage.store(key, value)
      expect(storage.fetch('expired_key')).to be_nil
      expect(storage.instance_variable_get(:@ttl_store)['expired_key']).to be_nil
    end
  end
end 