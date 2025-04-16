# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/configuration_facade'

module TypeBalancer
  module Rails
    RSpec.describe ConfigurationFacade do
      let(:facade) { described_class.new }

      describe '#initialize' do
        it 'creates a new Configuration instance' do
          expect(facade.instance_variable_get(:@config)).to be_a(TypeBalancer::Rails::Config::BaseConfiguration)
        end
      end

      describe '#configure' do
        it 'yields the configuration object and returns self' do
          expect { |b| facade.configure(&b) }.to yield_with_args(TypeBalancer::Rails::Config::BaseConfiguration)
          expect(facade.configure).to eq(facade)
        end
      end

      describe '#redis' do
        it 'returns redis settings from configuration' do
          expect(facade.redis).to eq(facade.instance_variable_get(:@config).redis_settings)
        end
      end

      describe '#cache' do
        it 'returns cache settings from configuration' do
          expect(facade.cache).to eq(facade.instance_variable_get(:@config).cache_settings)
        end
      end

      describe '#storage' do
        it 'returns storage settings from configuration' do
          expect(facade.storage).to eq(facade.instance_variable_get(:@config).storage_settings)
        end
      end

      describe '#pagination' do
        it 'returns pagination settings from configuration' do
          expect(facade.pagination).to eq(facade.instance_variable_get(:@config).pagination_settings)
        end
      end

      describe '#reset!' do
        it 'resets the configuration and returns self' do
          expect(facade.instance_variable_get(:@config)).to receive(:reset!)
          expect(facade.reset!).to eq(facade)
        end
      end

      describe 'configuration value methods' do
        let(:config) { facade.instance_variable_get(:@config) }

        before do
          allow(config).to receive_messages(
            redis_settings: { client: double, ttl: 3600, enabled: true },
            cache_settings: { store: double, ttl: 3600, enabled: true },
            storage_settings: { strategy: :redis },
            pagination_settings: { max_per_page: 100, cursor_buffer_multiplier: 1.5 }
          )
        end

        it 'returns redis client' do
          expect(facade.redis_client).to eq(config.redis_settings[:client])
        end

        it 'returns redis ttl' do
          expect(facade.redis_ttl).to eq(config.redis_settings[:ttl])
        end

        it 'returns redis enabled status' do
          expect(facade.redis_enabled?).to eq(config.redis_settings[:enabled])
        end

        it 'returns cache enabled status' do
          expect(facade.cache_enabled?).to eq(config.cache_settings[:enabled])
        end

        it 'returns cache ttl' do
          expect(facade.cache_ttl).to eq(config.cache_settings[:ttl])
        end

        it 'returns cache store' do
          expect(facade.cache_store).to eq(config.cache_settings[:store])
        end

        it 'returns storage strategy' do
          expect(facade.storage_strategy).to eq(config.storage_settings[:strategy])
        end

        it 'returns max per page' do
          expect(facade.max_per_page).to eq(config.pagination_settings[:max_per_page])
        end

        it 'returns cursor buffer multiplier' do
          expect(facade.cursor_buffer_multiplier).to eq(config.pagination_settings[:cursor_buffer_multiplier])
        end
      end

      describe 'validation methods' do
        let(:config) { facade.instance_variable_get(:@config) }

        describe '#validate_configuration!' do
          context 'when redis is enabled' do
            before do
              allow(config).to receive(:redis_settings).and_return(enabled: true, client: nil, ttl: 0)
            end

            it 'raises error when redis client is missing' do
              expect do
                facade.send(:validate_configuration!,
                            config)
              end.to raise_error(ArgumentError, 'Redis client required when Redis is enabled')
            end

            it 'raises error when redis ttl is not positive' do
              allow(config).to receive(:redis_settings).and_return(enabled: true, client: double, ttl: 0)
              expect do
                facade.send(:validate_configuration!, config)
              end.to raise_error(ArgumentError, 'Redis TTL must be positive')
            end
          end

          context 'when cache is enabled' do
            before do
              allow(config).to receive_messages(redis_settings: { enabled: false },
                                                cache_settings: {
                                                  enabled: true, ttl: 0
                                                })
            end

            it 'raises error when cache ttl is not positive' do
              expect do
                facade.send(:validate_configuration!, config)
              end.to raise_error(ArgumentError, 'Cache TTL must be positive')
            end
          end

          context 'when storage strategy is missing' do
            before do
              allow(config).to receive_messages(redis_settings: { enabled: false }, cache_settings: { enabled: false },
                                                storage_settings: { strategy: nil })
            end

            it 'raises error' do
              expect do
                facade.send(:validate_configuration!, config)
              end.to raise_error(ArgumentError, 'Storage strategy required')
            end
          end

          context 'when pagination settings are invalid' do
            before do
              allow(config).to receive_messages(redis_settings: { enabled: false }, cache_settings: { enabled: false },
                                                storage_settings: { strategy: :memory })
            end

            it 'raises error when max per page is not positive' do
              allow(config).to receive(:pagination_settings).and_return(max_per_page: 0, cursor_buffer_multiplier: 1.5)
              expect do
                facade.send(:validate_configuration!, config)
              end.to raise_error(ArgumentError, 'Max per page must be positive')
            end

            it 'raises error when cursor buffer multiplier is not greater than 1' do
              allow(config).to receive(:pagination_settings).and_return(max_per_page: 100,
                                                                        cursor_buffer_multiplier: 1.0)
              expect do
                facade.send(:validate_configuration!,
                            config)
              end.to raise_error(ArgumentError, 'Cursor buffer multiplier must be greater than 1')
            end
          end
        end

        describe '#pagination_settings' do
          it 'returns pagination settings' do
            allow(config).to receive(:pagination_settings).and_return(max_per_page: 100)
            expect(facade.pagination_settings).to eq(config.pagination_settings)
          end
        end

        describe '#validate_pagination_settings!' do
          it 'raises error when max_per_page is invalid' do
            expect do
              facade.send(:validate_pagination_settings!, max_per_page: 0)
            end.to raise_error(ArgumentError, 'max_per_page must be greater than 0')
          end
        end
      end

      describe '.redis' do
        it 'yields the configuration instance' do
          expect { |b| described_class.redis(&b) }.to yield_control
        end
      end

      describe '.cache' do
        it 'yields the configuration instance' do
          expect { |b| described_class.cache(&b) }.to yield_control
        end
      end

      describe '.storage' do
        it 'yields the storage strategy registry' do
          expect { |b| described_class.storage(&b) }.to yield_control
        end
      end

      describe '.pagination' do
        it 'yields the pagination configuration' do
          expect { |b| described_class.pagination(&b) }.to yield_control
        end
      end

      describe '.validate!' do
        before do
          described_class.reset!
        end

        context 'when redis is enabled' do
          before do
            described_class.redis do |config|
              config.enable_redis
              config.redis_client = redis_client
            end
          end

          context 'with valid redis client' do
            let(:redis_client) do
              double('Redis',
                     get: nil,
                     set: nil,
                     del: nil,
                     scan: nil)
            end

            it 'does not raise error' do
              expect { described_class.validate! }.not_to raise_error
            end
          end

          context 'with invalid redis client' do
            let(:redis_client) { nil }

            it 'raises ConfigurationError' do
              expect do
                described_class.validate!
              end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                                 'Redis client is not configured')
            end
          end

          context 'with redis client missing required methods' do
            let(:redis_client) { double('Redis') }

            it 'raises ConfigurationError for missing get' do
              expect do
                described_class.validate!
              end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                                 'Redis client must respond to :get')
            end

            it 'raises ConfigurationError for missing set' do
              allow(redis_client).to receive(:get)
              expect do
                described_class.validate!
              end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                                 'Redis client must respond to :set')
            end

            it 'raises ConfigurationError for missing del' do
              allow(redis_client).to receive(:get)
              allow(redis_client).to receive(:set)
              expect do
                described_class.validate!
              end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                                 'Redis client must respond to :del')
            end

            it 'raises ConfigurationError for missing scan' do
              allow(redis_client).to receive(:get)
              allow(redis_client).to receive(:set)
              allow(redis_client).to receive(:del)
              expect do
                described_class.validate!
              end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                                 'Redis client must respond to :scan')
            end
          end
        end

        context 'when cache is enabled' do
          before do
            described_class.cache(&:enable_cache)
          end

          context 'with valid cache store' do
            let(:cache_store) do
              double('CacheStore',
                     read: nil,
                     write: nil,
                     delete: nil)
            end

            before do
              allow(::Rails).to receive(:cache).and_return(cache_store)
            end

            it 'does not raise error' do
              expect { described_class.validate! }.not_to raise_error
            end
          end

          context 'with no cache store' do
            before do
              allow(::Rails).to receive(:cache).and_return(nil)
            end

            it 'raises ConfigurationError' do
              expect do
                described_class.validate!
              end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                                 'Cache store is not configured')
            end
          end

          context 'with cache store missing required methods' do
            let(:cache_store) { double('CacheStore') }

            before do
              allow(::Rails).to receive(:cache).and_return(cache_store)
            end

            it 'raises ConfigurationError for missing read' do
              expect do
                described_class.validate!
              end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                                 'Cache store must respond to :read')
            end

            it 'raises ConfigurationError for missing write' do
              allow(cache_store).to receive(:read)
              expect do
                described_class.validate!
              end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                                 'Cache store must respond to :write')
            end

            it 'raises ConfigurationError for missing delete' do
              allow(cache_store).to receive(:read)
              allow(cache_store).to receive(:write)
              expect do
                described_class.validate!
              end.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError,
                                 'Cache store must respond to :delete')
            end
          end
        end
      end
    end
  end
end
