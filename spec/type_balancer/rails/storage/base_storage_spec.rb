# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Storage::BaseStorage do
  # Create a concrete test class to verify the interface
  let(:test_storage_class) do
    Class.new(described_class) do
      def store(key, value, ttl = nil)
        validate_key!(key)
        validate_value!(value)
        { key: key, value: value, ttl: ttl }
      end

      def fetch(key)
        validate_key!(key)
        { key: key }
      end

      def delete(key)
        validate_key!(key)
        { key: key }
      end

      def clear
        true
      end
    end
  end

  let(:storage) { test_storage_class.new }
  let(:valid_key) { 'test_key' }
  let(:valid_value) { { data: 'test_value' } }

  describe '#initialize' do
    it 'accepts options hash' do
      options = { ttl: 3600 }
      instance = test_storage_class.new(options)
      expect(instance.send(:options)).to eq(options)
    end

    it 'defaults to empty options' do
      instance = test_storage_class.new
      expect(instance.send(:options)).to eq({})
    end
  end

  describe 'interface methods' do
    subject { described_class.new }

    it 'requires implementation of #store' do
      expect { subject.store('key', 'value') }.to raise_error(
        NotImplementedError,
        'TypeBalancer::Rails::Storage::BaseStorage must implement #store'
      )
    end

    it 'requires implementation of #fetch' do
      expect { subject.fetch('key') }.to raise_error(
        NotImplementedError,
        'TypeBalancer::Rails::Storage::BaseStorage must implement #fetch'
      )
    end

    it 'requires implementation of #delete' do
      expect { subject.delete('key') }.to raise_error(
        NotImplementedError,
        'TypeBalancer::Rails::Storage::BaseStorage must implement #delete'
      )
    end

    it 'requires implementation of #clear' do
      expect { subject.clear }.to raise_error(
        NotImplementedError,
        'TypeBalancer::Rails::Storage::BaseStorage must implement #clear'
      )
    end
  end

  describe '#validate_key!' do
    context 'with valid keys' do
      it 'accepts string keys' do
        expect { storage.store('string_key', valid_value) }.not_to raise_error
      end

      it 'accepts symbol keys' do
        expect { storage.store(:symbol_key, valid_value) }.not_to raise_error
      end
    end

    context 'with invalid keys' do
      it 'rejects nil keys' do
        expect { storage.store(nil, valid_value) }.to raise_error(
          ArgumentError,
          'Key cannot be nil'
        )
      end

      it 'rejects non-string/symbol keys' do
        expect { storage.store(123, valid_value) }.to raise_error(
          ArgumentError,
          'Key must be a string or symbol'
        )
      end

      it 'rejects empty string keys' do
        expect { storage.store('', valid_value) }.to raise_error(
          ArgumentError,
          'Key cannot be empty'
        )
      end

      it 'rejects blank string keys' do
        expect { storage.store('   ', valid_value) }.to raise_error(
          ArgumentError,
          'Key cannot be empty'
        )
      end
    end
  end

  describe '#validate_value!' do
    context 'with valid values' do
      it 'accepts objects that respond to to_json' do
        expect { storage.store(valid_key, valid_value) }.not_to raise_error
      end

      it 'accepts strings' do
        expect { storage.store(valid_key, 'string_value') }.not_to raise_error
      end

      it 'accepts numbers' do
        expect { storage.store(valid_key, 42) }.not_to raise_error
      end

      it 'accepts arrays' do
        expect { storage.store(valid_key, [1, 2, 3]) }.not_to raise_error
      end

      it 'accepts hashes' do
        expect { storage.store(valid_key, { a: 1 }) }.not_to raise_error
      end
    end

    context 'with invalid values' do
      it 'rejects nil values' do
        expect { storage.store(valid_key, nil) }.to raise_error(
          ArgumentError,
          'Value cannot be nil'
        )
      end

      it 'rejects objects that do not respond to to_json' do
        non_json_object = Object.new
        allow(non_json_object).to receive(:respond_to?).with(:to_json).and_return(false)

        expect { storage.store(valid_key, non_json_object) }.to raise_error(
          ArgumentError,
          'Value must respond to to_json'
        )
      end
    end
  end

  describe 'concrete implementation' do
    it 'can store and validate data' do
      result = storage.store(valid_key, valid_value, 3600)
      expect(result).to eq(
        key: valid_key,
        value: valid_value,
        ttl: 3600
      )
    end

    it 'can fetch and validate keys' do
      result = storage.fetch(valid_key)
      expect(result).to eq(key: valid_key)
    end

    it 'can delete and validate keys' do
      result = storage.delete(valid_key)
      expect(result).to eq(key: valid_key)
    end

    it 'can clear storage' do
      expect(storage.clear).to be true
    end
  end
end 