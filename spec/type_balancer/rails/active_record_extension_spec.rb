# frozen_string_literal: true

require 'spec_helper'
require 'type_balancer/rails/type_balancer_collection'
require 'type_balancer/rails/cache_invalidation'

RSpec.describe TypeBalancer::Rails::ActiveRecordExtension do
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      attr_accessor :id

      def self.table_name = 'test_models'
      def self.primary_key = 'id'
      def self.after_commit(*args); end
    end
  end

  before do
    # Ensure Rails.logger is mocked

    # Mock Rails.cache
    allow(Rails).to receive_messages(logger: double('Logger').as_null_object, cache: double('Cache').as_null_object)

    # Mock storage adapter
    storage_adapter = double('TypeBalancer::Rails::Config::ConfigStorageAdapter').as_null_object
    allow(TypeBalancer::Rails).to receive(:storage_adapter).and_return(storage_adapter)

    # Include the module properly
    test_class.include(described_class)
  end

  describe '.balance_by_type' do
    it 'sets type_balancer_options' do
      options = { ttl: 3600, type_field: :media_type }
      test_class.balance_by_type(options)
      expect(test_class.type_balancer_options).to eq(options.freeze)
    end

    it 'includes CacheInvalidation module' do
      test_class.balance_by_type
      expect(test_class.included_modules).to include(TypeBalancer::Rails::CacheInvalidation)
    end

    it 'includes TypeBalancerCollection module' do
      test_class.balance_by_type
      expect(test_class.included_modules).to include(TypeBalancer::Rails::TypeBalancerCollection)
    end

    it 'uses default options when none provided' do
      test_class.balance_by_type
      expect(test_class.type_balancer_options).to eq({}.freeze)
    end
  end

  describe 'cache invalidation' do
    before do
      test_class.balance_by_type
    end

    it 'includes CacheInvalidation module' do
      expect(test_class.included_modules).to include(TypeBalancer::Rails::CacheInvalidation)
    end

    it 'defines after_commit callback for cache invalidation' do
      expect(test_class).to respond_to(:after_commit)
    end
  end
end
