# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/configuration_facade'

module TypeBalancer
  module Rails
    RSpec.describe ConfigurationFacade do
      let(:redis_client) do
        instance_double(Redis).tap do |client|
          allow(client).to receive_messages(
            'get' => nil,
            'set' => nil,
            'del' => nil,
            'scan' => nil
          )
        end
      end
      let(:cache_store) { instance_double(ActiveSupport::Cache::Store) }
      let(:storage_strategy) { instance_double(TypeBalancer::Rails::Strategies::BaseStrategy) }
      let(:storage_adapter) { instance_double(TypeBalancer::Rails::Config::ConfigStorageAdapter) }
      let(:configuration) { instance_double(TypeBalancer::Rails::Config::BaseConfiguration) }

      before do
        allow(TypeBalancer::Rails::Config::BaseConfiguration).to receive(:new).and_return(configuration)
        allow(configuration).to receive_messages(
          'storage_strategy' => storage_strategy,
          'redis_client' => redis_client,
          'cache_store' => cache_store,
          'redis_enabled?' => false,
          'cache_enabled?' => false,
          'redis_ttl' => 3600,
          'cache_ttl' => 3600,
          'max_per_page' => 100,
          'cursor_buffer_multiplier' => 2,
          'enable_redis' => nil,
          'enable_cache' => nil,
          'redis_client=' => nil,
          'cache_store=' => nil
        )

        described_class.instance_variable_set(:@configuration, nil)
      end

      after do
        described_class.instance_variable_set(:@configuration, nil)
      end

      describe '.validate!' do
        context 'when storage strategy is not set' do
          before do
            allow(configuration).to receive(:storage_strategy).and_return(nil)
          end

          it 'raises error' do
            expect { described_class.validate! }.to raise_error(ArgumentError, 'Storage strategy required')
          end
        end

        context 'when max per page is not set' do
          before do
            allow(configuration).to receive(:max_per_page).and_return(nil)
          end

          it 'raises error' do
            expect { described_class.validate! }.to raise_error(ArgumentError, 'Max per page must be positive')
          end
        end

        context 'when max per page is not positive' do
          before do
            allow(configuration).to receive(:max_per_page).and_return(0)
          end

          it 'raises error' do
            expect { described_class.validate! }.to raise_error(ArgumentError, 'Max per page must be positive')
          end
        end

        context 'when redis is enabled' do
          before do
            allow(configuration).to receive(:redis_enabled?).and_return(true)
            described_class.configure(&:enable_redis)
          end

          context 'when redis client is not set' do
            before do
              allow(configuration).to receive(:redis_client).and_return(nil)
            end

            it 'raises error' do
              expect do
                described_class.validate!
              end.to raise_error(ArgumentError, 'Redis client required when Redis is enabled')
            end
          end

          context 'when redis client is set' do
            context 'when redis ttl is not set' do
              before do
                allow(configuration).to receive(:redis_ttl).and_return(nil)
              end

              it 'raises error' do
                expect { described_class.validate! }.to raise_error(ArgumentError, 'Redis TTL must be positive')
              end
            end

            context 'when redis ttl is not positive' do
              before do
                allow(configuration).to receive(:redis_ttl).and_return(0)
              end

              it 'raises error' do
                expect { described_class.validate! }.to raise_error(ArgumentError, 'Redis TTL must be positive')
              end
            end
          end
        end

        context 'when cache is enabled' do
          before do
            allow(configuration).to receive(:cache_enabled?).and_return(true)
            described_class.configure(&:enable_cache)
          end

          context 'when cache store is not set' do
            before do
              allow(configuration).to receive(:cache_store).and_return(nil)
            end

            it 'raises error' do
              expect { described_class.validate! }.to raise_error(ArgumentError, 'Cache store must be set')
            end
          end

          context 'when cache store is set' do
            before do
              allow(cache_store).to receive_messages(
                'read' => nil,
                'write' => nil,
                'delete' => nil
              )
            end

            context 'when cache ttl is not set' do
              before do
                allow(configuration).to receive(:cache_ttl).and_return(nil)
              end

              it 'raises error' do
                expect { described_class.validate! }.to raise_error(ArgumentError, 'Cache TTL must be positive')
              end
            end

            context 'when cache ttl is not positive' do
              before do
                allow(configuration).to receive(:cache_ttl).and_return(0)
              end

              it 'raises error' do
                expect { described_class.validate! }.to raise_error(ArgumentError, 'Cache TTL must be positive')
              end
            end
          end
        end
      end
    end
  end
end
