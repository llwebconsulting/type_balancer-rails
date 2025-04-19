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
      let(:configuration) { instance_double(TypeBalancer::Rails::Config::RuntimeConfiguration) }
      let(:strategy_manager) { instance_double(TypeBalancer::Rails::Config::StrategyManager) }

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

        allow(TypeBalancer::Rails::Config::RuntimeConfiguration).to receive(:new).and_return(configuration)
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
          'redis_enabled' => configuration,
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
          'reset!' => configuration,
          'strategy_manager' => strategy_manager,
          'validate!' => true
        )

        allow(configuration).to receive(:redis).and_yield(configuration).and_return(configuration)
        allow(configuration).to receive(:cache).and_yield(configuration).and_return(configuration)
        allow(configuration).to receive(:pagination).and_yield(configuration).and_return(configuration)

        allow(storage_adapter).to receive_messages(
          configure_redis: true,
          configure_cache: true,
          validate!: true
        )

        allow(strategy_manager).to receive_messages(
          register: true,
          validate!: true
        )

        allow(redis_client).to receive_messages(
          get: true,
          set: true,
          del: true,
          scan: true,
          ping: 'PONG'
        )

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
          described_class.configure(&:redis_enabled)
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

      describe '.initialize!' do
        it 'resets configuration and registers defaults' do
          expect(described_class).to receive(:reset!)
          expect(described_class).to receive(:register_defaults)
          expect(configuration).to receive(:validate!)
          described_class.initialize!
        end
      end

      describe '.register_defaults' do
        let(:cursor_strategy) { instance_double(TypeBalancer::Rails::Strategies::CursorStrategy) }
        let(:redis_strategy) { instance_double(TypeBalancer::Rails::Strategies::RedisStrategy) }

        before do
          allow(TypeBalancer::Rails::Strategies::CursorStrategy).to receive(:new).and_return(cursor_strategy)
          allow(TypeBalancer::Rails::Strategies::RedisStrategy).to receive(:new).and_return(redis_strategy)
        end

        it 'registers default strategies' do
          expect(strategy_manager).to receive(:register).with(:cursor, cursor_strategy)
          expect(strategy_manager).to receive(:register).with(:redis, redis_strategy)
          described_class.register_defaults
        end
      end

      describe '.validate!' do
        context 'with valid settings' do
          it 'validates successfully' do
            expect { described_class.validate! }.not_to raise_error
          end
        end

        context 'with invalid redis settings' do
          before do
            allow(configuration).to receive(:redis_ttl).and_return(0)
          end

          it 'raises an error' do
            expect { described_class.validate! }.to raise_error(ArgumentError, 'Redis TTL must be positive')
          end
        end

        context 'with invalid cache settings' do
          before do
            allow(configuration).to receive(:cache_ttl).and_return(0)
          end

          it 'raises an error' do
            expect { described_class.validate! }.to raise_error(ArgumentError, 'Cache TTL must be positive')
          end
        end
      end

      describe 'redis configuration' do
        it 'delegates redis client configuration' do
          expect(configuration).to receive(:redis_client).at_least(:once)
          described_class.redis_client
        end

        it 'validates redis client methods' do
          expect(redis_client).to receive(:get)
          expect(redis_client).to receive(:set)
          expect(redis_client).to receive(:del)
          expect(redis_client).to receive(:scan)
          described_class.validate!
        end
      end

      describe 'cache configuration' do
        it 'delegates cache configuration' do
          expect(configuration).to receive(:cache_enabled?).at_least(:once)
          described_class.cache_enabled?
        end

        it 'validates cache store methods' do
          store = Rails.cache
          expect(store).to respond_to(:read)
          expect(store).to respond_to(:write)
          expect(store).to respond_to(:delete)
        end
      end
    end
  end
end
