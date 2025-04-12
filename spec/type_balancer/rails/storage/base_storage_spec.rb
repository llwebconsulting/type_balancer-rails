# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Storage::BaseStorage do
  let(:storage_class) { Class.new(described_class) }
  let(:storage) { storage_class.new }

  describe '#store' do
    it 'raises NotImplementedError' do
      expect { storage.store('key', 'value') }.to raise_error(NotImplementedError)
    end
  end

  describe '#fetch' do
    it 'raises NotImplementedError' do
      expect { storage.fetch('key') }.to raise_error(NotImplementedError)
    end
  end

  describe '#delete' do
    it 'raises NotImplementedError' do
      expect { storage.delete('key') }.to raise_error(NotImplementedError)
    end
  end

  describe '#clear' do
    it 'raises NotImplementedError' do
      expect { storage.clear }.to raise_error(NotImplementedError)
    end
  end

  describe '#validate_key!' do
    subject(:validate_key!) { storage.send(:validate_key!, key) }

    context 'with valid keys' do
      it 'accepts string keys' do
        key = 'valid_key'
        expect { validate_key! }.not_to raise_error
      end

      it 'accepts symbol keys' do
        key = :valid_key
        expect { validate_key! }.not_to raise_error
      end
    end

    context 'with invalid keys' do
      it 'rejects nil keys' do
        key = nil
        expect { validate_key! }.to raise_error(ArgumentError, 'Key cannot be nil')
      end

      it 'rejects non-string/symbol keys' do
        key = 123
        expect { validate_key! }.to raise_error(ArgumentError, 'Key must be a string or symbol')
      end
    end
  end

  describe '#validate_value!' do
    subject(:validate_value!) { storage.send(:validate_value!, value) }

    context 'with valid values' do
      it 'accepts non-nil values' do
        value = 'valid_value'
        expect { validate_value! }.not_to raise_error
      end
    end

    context 'with invalid values' do
      it 'rejects nil values' do
        value = nil
        expect { validate_value! }.to raise_error(ArgumentError, 'Value cannot be nil')
      end
    end
  end

  describe '#validate_ttl!' do
    subject(:validate_ttl!) { storage.send(:validate_ttl!, ttl) }

    context 'with valid TTL' do
      it 'accepts nil TTL' do
        ttl = nil
        expect { validate_ttl! }.not_to raise_error
      end

      it 'accepts positive integer TTL' do
        ttl = 3600
        expect { validate_ttl! }.not_to raise_error
      end
    end

    context 'with invalid TTL' do
      it 'rejects non-integer TTL' do
        ttl = 'invalid'
        expect { validate_ttl! }.to raise_error(ArgumentError, 'TTL must be a positive integer')
      end

      it 'rejects negative TTL' do
        ttl = -1
        expect { validate_ttl! }.to raise_error(ArgumentError, 'TTL must be a positive integer')
      end

      it 'rejects zero TTL' do
        ttl = 0
        expect { validate_ttl! }.to raise_error(ArgumentError, 'TTL must be a positive integer')
      end
    end
  end
end 