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
      let(:configuration) { instance_double(TypeBalancer::Rails::Config::RuntimeConfiguration) }

      before do
        allow(TypeBalancer::Rails::Config::RuntimeConfiguration).to receive(:new).and_return(configuration)
        allow(configuration).to receive_messages(
          'storage_adapter' => storage_adapter,
          'redis_enabled?' => true,
          'cache_enabled?' => true,
          'redis_ttl' => 3600,
          'cache_ttl' => 3600,
          'redis_url' => 'redis://localhost:6379/1',
          'cache_store' => :memory_store
        )

        described_class.instance_variable_set(:@configuration, nil)
      end

      after do
        described_class.instance_variable_set(:@configuration, nil)
      end

      describe '.validate!' do
        context 'when configuration is valid' do
          it 'does not raise error' do
            expect { described_class.validate! }.not_to raise_error
          end
        end

        context 'when redis is enabled' do
          it 'validates redis_url presence' do
            allow(configuration).to receive(:redis_url).and_return(nil)
            expect { described_class.validate! }.to raise_error(
              TypeBalancer::Rails::ConfigurationError,
              'Redis URL must be provided when Redis is enabled'
            )
          end

          it 'validates redis_ttl is a positive integer' do
            allow(configuration).to receive(:redis_ttl).and_return(-1)
            expect { described_class.validate! }.to raise_error(
              TypeBalancer::Rails::ConfigurationError,
              'Redis TTL must be a positive integer'
            )
          end
        end

        context 'when cache is enabled' do
          it 'validates cache_store presence' do
            allow(configuration).to receive(:cache_store).and_return(nil)
            expect { described_class.validate! }.to raise_error(
              TypeBalancer::Rails::ConfigurationError,
              'Cache store must be provided when cache is enabled'
            )
          end

          it 'validates cache_ttl is a positive integer' do
            allow(configuration).to receive(:cache_ttl).and_return(-1)
            expect { described_class.validate! }.to raise_error(
              TypeBalancer::Rails::ConfigurationError,
              'Cache TTL must be a positive integer'
            )
          end
        end
      end
    end
  end
end
