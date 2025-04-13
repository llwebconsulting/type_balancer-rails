# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/configuration/redis_config'

module TypeBalancer
  module Rails
    class Configuration
      RSpec.describe RedisConfig do
        let(:redis_config) { described_class.new }
        let(:mock_client) { instance_double('Redis') }

        describe '#initialize' do
          context 'with default parameters' do
            it 'should set default values' do
              expect(redis_config.enabled?).to be false
              expect(redis_config.ttl).to eq(3600)
              expect(redis_config.client).to be_nil
            end
          end

          context 'with custom parameters' do
            let(:redis_config) { described_class.new(ttl: 7200) }

            it 'should set custom values' do
              expect(redis_config.enabled?).to be false
              expect(redis_config.ttl).to eq(7200)
              expect(redis_config.client).to be_nil
            end
          end
        end

        describe '#configure' do
          let(:redis_class) { class_double('Redis').as_stubbed_const }

          before do
            allow(redis_class).to receive(:new).and_return(mock_client)
          end

          it 'should create a new Redis client' do
            expect(redis_class).to receive(:new)
            redis_config.configure
          end

          it 'should store the client' do
            redis_config.configure
            expect(redis_config.client).to eq(mock_client)
          end

          it 'should enable Redis' do
            redis_config.configure
            expect(redis_config.enabled?).to be true
          end

          context 'when given a block' do
            it 'should yield self to the block' do
              expect { |b| redis_config.configure(&b) }.to yield_with_args(redis_config)
            end
          end

          it 'should return self for chaining' do
            expect(redis_config.configure).to eq(redis_config)
          end
        end

        describe '#register_client' do
          it 'should store the provided client' do
            redis_config.register_client(mock_client)
            expect(redis_config.client).to eq(mock_client)
          end

          it 'should enable Redis' do
            redis_config.register_client(mock_client)
            expect(redis_config.enabled?).to be true
          end

          it 'should return self for chaining' do
            expect(redis_config.register_client(mock_client)).to eq(redis_config)
          end
        end

        describe '#enabled?' do
          it 'should return false by default' do
            expect(redis_config.enabled?).to be false
          end

          it 'should return true after configuring' do
            redis_config.configure
            expect(redis_config.enabled?).to be true
          end

          it 'should return true after registering client' do
            redis_config.register_client(mock_client)
            expect(redis_config.enabled?).to be true
          end
        end

        describe '#ttl=' do
          context 'when given a numeric value' do
            it 'should set the TTL' do
              redis_config.ttl = 1800
              expect(redis_config.ttl).to eq(1800)
            end
          end

          context 'when given a string value' do
            it 'should convert to integer' do
              redis_config.ttl = '1800'
              expect(redis_config.ttl).to eq(1800)
            end
          end
        end

        describe '#reset!' do
          before do
            redis_config.configure
            redis_config.ttl = 1800
          end

          it 'should reset to default values' do
            redis_config.reset!
            expect(redis_config.enabled?).to be false
            expect(redis_config.client).to be_nil
            expect(redis_config.ttl).to eq(3600)
          end
        end
      end
    end
  end
end 