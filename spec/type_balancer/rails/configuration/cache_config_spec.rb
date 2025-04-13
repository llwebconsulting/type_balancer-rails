# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/configuration/cache_config'

module TypeBalancer
  module Rails
    class Configuration
      RSpec.describe CacheConfig do
        let(:cache_config) { described_class.new }
        let(:mock_store) { instance_double('ActiveSupport::Cache::Store') }

        describe '#initialize' do
          context 'with default parameters' do
            it 'should set default values' do
              expect(cache_config.enabled).to be true
              expect(cache_config.ttl).to eq(3600)
              expect(cache_config.store).to be_nil
            end
          end

          context 'with custom parameters' do
            let(:cache_config) { described_class.new(enabled: false, ttl: 7200) }

            it 'should set custom values' do
              expect(cache_config.enabled).to be false
              expect(cache_config.ttl).to eq(7200)
              expect(cache_config.store).to be_nil
            end
          end
        end

        describe '#configure' do
          before do
            allow(::Rails).to receive(:cache=)
            allow(::Rails).to receive(:cache).and_return(mock_store)
          end

          context 'when given a store' do
            it 'should set the Rails cache store' do
              expect(::Rails).to receive(:cache=).with(mock_store)
              cache_config.configure(mock_store)
            end

            it 'should update the internal store reference' do
              cache_config.configure(mock_store)
              expect(cache_config.store).to eq(mock_store)
            end
          end

          context 'when given a block' do
            it 'should yield the Rails cache to the block' do
              expect { |b| cache_config.configure(&b) }.to yield_with_args(mock_store)
            end
          end

          context 'when given both store and block' do
            it 'should set the store and yield to the block' do
              expect(::Rails).to receive(:cache=).with(mock_store).ordered
              expect { |b| cache_config.configure(mock_store, &b) }.to yield_with_args(mock_store)
            end
          end

          it 'should return self for chaining' do
            expect(cache_config.configure).to eq(cache_config)
          end
        end

        describe '#enable!' do
          before { cache_config.disable! }

          it 'should enable caching' do
            cache_config.enable!
            expect(cache_config.enabled).to be true
          end
        end

        describe '#disable!' do
          it 'should disable caching' do
            cache_config.disable!
            expect(cache_config.enabled).to be false
          end
        end

        describe '#ttl=' do
          context 'when given a numeric value' do
            it 'should set the TTL' do
              cache_config.ttl = 1800
              expect(cache_config.ttl).to eq(1800)
            end
          end

          context 'when given a string value' do
            it 'should convert to integer' do
              cache_config.ttl = '1800'
              expect(cache_config.ttl).to eq(1800)
            end
          end
        end

        describe '#reset!' do
          before do
            cache_config.disable!
            cache_config.configure(mock_store)
            cache_config.ttl = 1800
          end

          it 'should reset to default values' do
            cache_config.reset!
            expect(cache_config.enabled).to be true
            expect(cache_config.store).to be_nil
            expect(cache_config.ttl).to eq(3600)
          end
        end
      end
    end
  end
end 