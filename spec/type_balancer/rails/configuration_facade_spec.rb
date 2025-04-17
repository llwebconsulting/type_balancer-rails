# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/configuration_facade'

module TypeBalancer
  module Rails
    RSpec.describe ConfigurationFacade do
      let(:redis_client) { instance_double(Redis) }
      let(:cache_store) { instance_double(ActiveSupport::Cache::Store) }
      let(:storage_strategy) { instance_double(TypeBalancer::Rails::Strategies::BaseStrategy) }
      let(:storage_adapter) { instance_double(TypeBalancer::Rails::Config::ConfigStorageAdapter) }
      let(:configuration) { instance_double(TypeBalancer::Rails::Config::BaseConfiguration) }

      before do
        allow(redis_client).to receive_messages(
          get: nil,
          set: nil,
          del: nil,
          scan: nil,
          respond_to?: true
        )

        allow(cache_store).to receive_messages(
          read: nil,
          write: nil,
          delete: nil,
          respond_to?: true
        )

        allow(TypeBalancer::Rails::Config::BaseConfiguration).to receive(:new).and_return(configuration)
        allow(configuration).to receive_messages(
          'storage_adapter' => storage_adapter,
          'storage_strategy' => storage_strategy,
          'redis_client' => redis_client,
          'cache_store' => cache_store,
          'redis_enabled?' => true,
          'cache_enabled?' => true,
          'redis_ttl' => 3600,
          'cache_ttl' => 3600,
          'max_per_page' => 100,
          'cursor_buffer_multiplier' => 2,
          'redis_settings' => {
            client: redis_client,
            ttl: 3600,
            enabled: true
          },
          'cache_settings' => {
            store: cache_store,
            ttl: 3600,
            enabled: true
          },
          'storage_settings' => {
            strategy: storage_strategy
          },
          'pagination_settings' => {
            max_per_page: 100,
            cursor_buffer_multiplier: 2
          },
          'enable_redis' => configuration,
          'enable_cache' => configuration,
          'redis' => configuration,
          'cache' => configuration,
          'pagination' => configuration,
          'storage_strategy=' => nil,
          'redis_client=' => nil,
          'redis_ttl=' => nil,
          'redis_enabled=' => nil,
          'cache_store=' => nil,
          'cache_ttl=' => nil,
          'cache_enabled=' => nil,
          'max_per_page=' => nil,
          'cursor_buffer_multiplier=' => nil,
          'reset!' => configuration
        )

        allow(configuration).to receive(:redis).and_yield(configuration).and_return(configuration)
        allow(configuration).to receive(:cache).and_yield(configuration).and_return(configuration)
        allow(configuration).to receive(:pagination).and_yield(configuration).and_return(configuration)

        described_class.instance_variable_set(:@configuration, nil)
      end

      after do
        described_class.instance_variable_set(:@configuration, nil)
      end

      describe '.configure' do
        it 'yields configuration object' do
          expect { |b| described_class.configure(&b) }.to yield_with_args(configuration)
        end

        it 'returns self' do
          expect(described_class.configure(&:itself)).to eq(described_class)
        end
      end

      describe '.reset!' do
        it 'resets configuration to default' do
          described_class.configure(&:enable_redis)
          described_class.configure(&:enable_cache)

          allow(configuration).to receive_messages(
            'redis_enabled?' => false,
            'cache_enabled?' => false
          )

          described_class.reset!

          expect(configuration.redis_enabled?).to be false
          expect(configuration.cache_enabled?).to be false
        end

        it 'returns self' do
          expect(described_class.reset!).to eq(described_class)
        end
      end
    end
  end
end
