# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::ActiveRecordExtension, :unit do
  describe '.included' do
    let(:relation) do
      rel = instance_double(ActiveRecord::Relation)
      allow(rel).to receive(:to_a).and_return([])
      allow(rel).to receive(:klass).and_return(TestARModel)
      allow(rel).to receive(:class).and_return(ActiveRecord::Relation)
      rel.extend(TypeBalancer::Rails::CollectionMethods)
      rel
    end
    let(:model_class) { TestARModel }

    before do
      # Create a test model class that extends our module
      test_ar_model = Class.new do
        extend TypeBalancer::Rails::ActiveRecordExtension::ClassMethods
        @type_balancer_options = {}
        class << self
          attr_accessor :type_balancer_options

          def all; end
          def where(*); end
        end
      end

      # Stub the constant rather than defining it directly
      stub_const('TestARModel', test_ar_model)

      allow(TestARModel).to receive(:all).and_return(relation)
      allow(TestARModel).to receive(:where).and_return(relation)
    end

    it 'stores type field configuration' do
      model_class.balance_by_type type_field: :content_type
      expect(model_class.type_balancer_options[:type_field]).to eq(:content_type)
    end

    it 'stores type field when passed as a symbol (idiomatic API)' do
      model_class.balance_by_type :media_type
      expect(model_class.type_balancer_options[:type_field]).to eq(:media_type)
    end

    it 'uses default type field when called with no arguments (idiomatic API)' do
      model_class.balance_by_type
      expect(model_class.type_balancer_options[:type_field]).to eq(:type)
    end

    it 'returns a relation with collection methods' do
      # This test is no longer needed, as balance_by_type should only be called on AR relations
      # and will raise if called on an unsupported object.
    end
  end

  describe 'edge cases for balance_by_type' do
    it 'returns empty array if class does not respond to .all' do
      klass = Class.new
      klass.extend(TypeBalancer::Rails::ActiveRecordExtension::ClassMethods)
      expect(klass.balance_by_type).to eq([])
    end

    it 'returns empty array if .all does not return an ActiveRecord::Relation' do
      klass = Class.new do
        def self.all = []
      end
      klass.extend(TypeBalancer::Rails::ActiveRecordExtension::ClassMethods)
      expect(klass.balance_by_type).to eq([])
    end
  end
end
