# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/configuration_facade'

module TypeBalancer
  module Rails
    RSpec.describe ConfigurationFacade do
      let(:facade) { described_class.new }

      describe '#initialize' do
        it 'creates a new Configuration instance' do
          expect(facade.instance_variable_get(:@config)).to be_a(Configuration)
        end
      end

      describe '#configure' do
        it 'yields the configuration object and returns self' do
          expect { |b| facade.configure(&b) }.to yield_with_args(Configuration)
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
          allow(config).to receive(:redis_settings).and_return(client: double, ttl: 3600, enabled: true)
          allow(config).to receive(:cache_settings).and_return(store: double, ttl: 3600, enabled: true)
          allow(config).to receive(:storage_settings).and_return(strategy: :redis)
          allow(config).to receive(:pagination_settings).and_return(max_per_page: 100, cursor_buffer_multiplier: 1.5)
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
              expect { facade.send(:validate_configuration!, config) }.to raise_error(ArgumentError, 'Redis client required when Redis is enabled')
            end

            it 'raises error when redis ttl is not positive' do
              allow(config).to receive(:redis_settings).and_return(enabled: true, client: double, ttl: 0)
              expect { facade.send(:validate_configuration!, config) }.to raise_error(ArgumentError, 'Redis TTL must be positive')
            end
          end

          context 'when cache is enabled' do
            before do
              allow(config).to receive(:redis_settings).and_return(enabled: false)
              allow(config).to receive(:cache_settings).and_return(enabled: true, ttl: 0)
            end

            it 'raises error when cache ttl is not positive' do
              expect { facade.send(:validate_configuration!, config) }.to raise_error(ArgumentError, 'Cache TTL must be positive')
            end
          end

          context 'when storage strategy is missing' do
            before do
              allow(config).to receive(:redis_settings).and_return(enabled: false)
              allow(config).to receive(:cache_settings).and_return(enabled: false)
              allow(config).to receive(:storage_settings).and_return(strategy: nil)
            end

            it 'raises error' do
              expect { facade.send(:validate_configuration!, config) }.to raise_error(ArgumentError, 'Storage strategy required')
            end
          end

          context 'when pagination settings are invalid' do
            before do
              allow(config).to receive(:redis_settings).and_return(enabled: false)
              allow(config).to receive(:cache_settings).and_return(enabled: false)
              allow(config).to receive(:storage_settings).and_return(strategy: :memory)
            end

            it 'raises error when max per page is not positive' do
              allow(config).to receive(:pagination_settings).and_return(max_per_page: 0, cursor_buffer_multiplier: 1.5)
              expect { facade.send(:validate_configuration!, config) }.to raise_error(ArgumentError, 'Max per page must be positive')
            end

            it 'raises error when cursor buffer multiplier is not greater than 1' do
              allow(config).to receive(:pagination_settings).and_return(max_per_page: 100, cursor_buffer_multiplier: 1.0)
              expect { facade.send(:validate_configuration!, config) }.to raise_error(ArgumentError, 'Cursor buffer multiplier must be greater than 1')
            end
          end
        end
      end
    end
  end
end 