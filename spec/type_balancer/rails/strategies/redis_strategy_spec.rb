# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Strategies::RedisStrategy do
  subject { described_class.new(collection, options) }

  let(:collection) { double('collection', object_id: 123) }
  let(:redis) { instance_double(Redis) }
  let(:options) { { ttl: 3600, redis: redis } }

  before do
    allow(TypeBalancer::Rails.configuration).to receive_messages(redis_client: redis, redis_enabled?: true)
    allow(TypeBalancer::Rails::Config::ConfigStorageAdapter).to receive_messages(cache_ttl: 3600, redis_enabled: true)
    allow(redis).to receive(:setex)
    allow(redis).to receive(:set)
    allow(redis).to receive(:get)
    allow(redis).to receive(:del)
    allow(redis).to receive(:keys).and_return([])
  end

  describe '#store' do
    context 'with ttl' do
      it 'stores value with expiration' do
        expect(redis).to receive(:setex).with('type_balancer:123:key', 3600, '{"foo":"bar"}')
        subject.store('key', { foo: 'bar' })
      end
    end

    context 'without ttl' do
      let(:options) { { redis: redis } }

      it 'stores value with default expiration' do
        expect(redis).to receive(:setex).with('type_balancer:123:key', 3600, '{"foo":"bar"}')
        subject.store('key', { foo: 'bar' })
      end
    end

    context 'with nil key' do
      it 'raises error' do
        expect { subject.store(nil, { foo: 'bar' }) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end

    context 'with nil value' do
      it 'raises error' do
        expect { subject.store('key', nil) }.to raise_error(ArgumentError, 'Value cannot be nil')
      end
    end
  end

  describe '#fetch' do
    context 'when key exists' do
      before do
        allow(redis).to receive(:get).with('type_balancer:123:key').and_return('{"foo":"bar"}')
      end

      it 'returns stored value' do
        expect(subject.fetch('key')).to eq({ foo: 'bar' })
      end
    end

    context 'when key does not exist' do
      before do
        allow(redis).to receive(:get).with('type_balancer:123:key').and_return(nil)
      end

      it 'returns nil' do
        expect(subject.fetch('key')).to be_nil
      end
    end

    context 'with nil key' do
      it 'raises error' do
        expect { subject.fetch(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end
  end

  describe '#delete' do
    it 'removes key' do
      expect(redis).to receive(:del).with('type_balancer:123:key')
      subject.delete('key')
    end

    context 'with nil key' do
      it 'raises error' do
        expect { subject.delete(nil) }.to raise_error(ArgumentError, 'Key cannot be nil')
      end
    end
  end

  describe '#clear' do
    before do
      allow(redis).to receive(:keys).with('type_balancer:123:*').and_return(['key1', 'key2'])
    end

    it 'removes all keys' do
      expect(redis).to receive(:del).with('key1', 'key2')
      subject.clear
    end
  end

  describe '#clear_for_scope' do
    let(:scope) { double('scope', object_id: 456) }

    before do
      allow(redis).to receive(:keys).with('type_balancer:456:*').and_return(['key1', 'key2'])
    end

    it 'removes all keys for scope' do
      expect(redis).to receive(:del).with('key1', 'key2')
      subject.clear_for_scope(scope)
    end
  end

  describe '#fetch_for_scope' do
    let(:scope) { double('scope', object_id: 456) }

    before do
      allow(redis).to receive(:keys).with('type_balancer:456:*').and_return(['type_balancer:456:key1',
                                                                             'type_balancer:456:key2'])
      allow(redis).to receive(:get).with('type_balancer:456:key1').and_return('{"foo":"bar"}')
      allow(redis).to receive(:get).with('type_balancer:456:key2').and_return('{"baz":"qux"}')
    end

    it 'returns all values for scope' do
      result = subject.fetch_for_scope(scope)
      expect(result).to eq({
                             'type_balancer:456:key1' => { foo: 'bar' },
                             'type_balancer:456:key2' => { baz: 'qux' }
                           })
    end

    context 'with empty scope' do
      before do
        allow(redis).to receive(:keys).with('type_balancer:456:*').and_return([])
      end

      it 'returns empty hash' do
        expect(subject.fetch_for_scope(scope)).to eq({})
      end
    end
  end

  describe '#execute' do
    context 'with value' do
      it 'stores value' do
        expect(redis).to receive(:setex).with('type_balancer:123:key', 3600, '{"foo":"bar"}')
        subject.execute('key', { foo: 'bar' })
      end
    end

    context 'without value' do
      before do
        allow(redis).to receive(:get).with('type_balancer:123:key').and_return('{"foo":"bar"}')
      end

      it 'fetches value' do
        expect(subject.execute('key')).to eq({ foo: 'bar' })
      end
    end
  end

  describe '#deep_symbolize_keys' do
    it 'symbolizes hash keys recursively' do
      input = { 'a' => { 'b' => { 'c' => 'd' } } }
      expected = { a: { b: { c: 'd' } } }
      expect(subject.send(:deep_symbolize_keys, input)).to eq(expected)
    end

    it 'handles arrays' do
      input = [{ 'a' => 'b' }, { 'c' => 'd' }]
      expected = [{ a: 'b' }, { c: 'd' }]
      expect(subject.send(:deep_symbolize_keys, input)).to eq(expected)
    end

    it 'returns non-hash/array values as is' do
      expect(subject.send(:deep_symbolize_keys, 'string')).to eq('string')
      expect(subject.send(:deep_symbolize_keys, 123)).to eq(123)
      expect(subject.send(:deep_symbolize_keys, true)).to be(true)
    end
  end
end
