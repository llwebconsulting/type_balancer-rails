# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::CacheInvalidation do
  let(:test_class) { mock_model_class("TestModel") }
  let(:storage_adapter) { instance_double('TypeBalancer::Rails::Config::ConfigStorageAdapter') }

  before do
    allow(TypeBalancer::Rails).to receive(:storage_adapter).and_return(storage_adapter)
    allow(storage_adapter).to receive(:clear)
    test_class.include(described_class)
  end

  describe 'module inclusion' do
    it 'includes ActiveRecord::Callbacks' do
      expect(test_class.included_modules).to include(ActiveRecord::Callbacks)
    end

    it 'defines after_commit callback' do
      expect(test_class._commit_callbacks.map(&:filter)).to include(:invalidate_type_balancer_cache)
    end
  end

  describe '#invalidate_type_balancer_cache' do
    it 'clears the storage adapter cache' do
      expect(storage_adapter).to receive(:clear)
      test_class.new.invalidate_type_balancer_cache
    end

    it 'is called after commit' do
      instance = test_class.new
      expect(instance).to receive(:invalidate_type_balancer_cache)
      instance.run_callbacks(:commit)
    end

    context 'when storage adapter is not available' do
      before do
        allow(TypeBalancer::Rails).to receive(:storage_adapter).and_return(nil)
      end

      it 'raises an error' do
        expect {
          test_class.new.invalidate_type_balancer_cache
        }.to raise_error(NoMethodError)
      end
    end

    context 'when clear fails' do
      before do
        allow(storage_adapter).to receive(:clear).and_raise(Redis::CannotConnectError)
      end

      it 'allows the error to propagate' do
        expect {
          test_class.new.invalidate_type_balancer_cache
        }.to raise_error(Redis::CannotConnectError)
      end
    end
  end

  describe 'thread safety' do
    it 'handles concurrent cache invalidation' do
      threads = []
      mutex = Mutex.new
      results = []

      5.times do
        threads << Thread.new do
          begin
            test_class.new.invalidate_type_balancer_cache
            mutex.synchronize { results << :success }
          rescue StandardError => e
            mutex.synchronize { results << e }
          end
        end
      end

      threads.each(&:join)
      expect(results.count(:success)).to eq(5)
    end
  end
end 