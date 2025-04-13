# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::Errors do
  describe 'Error class hierarchy' do
    it 'has a base Error class that inherits from StandardError' do
      expect(TypeBalancer::Rails::Errors::Error).to be < StandardError
    end

    {
      'ConfigurationError' => 'when configuration validation fails',
      'StrategyError' => 'when a strategy validation fails',
      'CacheError' => 'when cache operations fail',
      'RedisError' => 'when Redis operations fail',
      'ValidationError' => 'when invalid input is provided',
      'DependencyError' => 'when a required dependency is missing'
    }.each do |error_name, description|
      describe "::#{error_name}" do
        let(:error_class) { TypeBalancer::Rails::Errors.const_get(error_name) }
        
        it "inherits from Error base class" do
          expect(error_class).to be < TypeBalancer::Rails::Errors::Error
        end

        it "can be instantiated with a message" do
          message = "Error occurred #{description}"
          error = error_class.new(message)
          expect(error.message).to eq(message)
        end

        it "can be raised and caught" do
          message = "Error occurred #{description}"
          
          expect {
            raise error_class, message
          }.to raise_error(error_class, message)
        end

        it "can be caught as a TypeBalancer::Rails::Errors::Error" do
          expect {
            raise error_class, "Some message"
          }.to raise_error(TypeBalancer::Rails::Errors::Error)
        end
      end
    end
  end

  describe 'Error usage examples' do
    it 'ConfigurationError provides helpful configuration error messages' do
      expect {
        raise TypeBalancer::Rails::Errors::ConfigurationError, 'Invalid cache configuration'
      }.to raise_error(TypeBalancer::Rails::Errors::ConfigurationError, 'Invalid cache configuration')
    end

    it 'StrategyError provides helpful strategy error messages' do
      expect {
        raise TypeBalancer::Rails::Errors::StrategyError, 'Unknown strategy: custom'
      }.to raise_error(TypeBalancer::Rails::Errors::StrategyError, 'Unknown strategy: custom')
    end

    it 'CacheError provides helpful cache error messages' do
      expect {
        raise TypeBalancer::Rails::Errors::CacheError, 'Cache store not configured'
      }.to raise_error(TypeBalancer::Rails::Errors::CacheError, 'Cache store not configured')
    end

    it 'RedisError provides helpful Redis error messages' do
      expect {
        raise TypeBalancer::Rails::Errors::RedisError, 'Redis connection failed'
      }.to raise_error(TypeBalancer::Rails::Errors::RedisError, 'Redis connection failed')
    end

    it 'ValidationError provides helpful validation error messages' do
      expect {
        raise TypeBalancer::Rails::Errors::ValidationError, 'Invalid type field'
      }.to raise_error(TypeBalancer::Rails::Errors::ValidationError, 'Invalid type field')
    end

    it 'DependencyError provides helpful dependency error messages' do
      expect {
        raise TypeBalancer::Rails::Errors::DependencyError, 'Redis gem not installed'
      }.to raise_error(TypeBalancer::Rails::Errors::DependencyError, 'Redis gem not installed')
    end
  end
end 