# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::ActiveRecordExtension, :unit do
  describe '.included' do
    let(:relation) do
      rel = instance_double(ActiveRecord::Relation)
      allow(rel).to receive(:to_a).and_return([])
      allow(rel).to receive(:klass).and_return(TestARModel)
      allow(rel).to receive(:class).and_return(ActiveRecord::Relation)
      allow(rel).to receive(:balance_by_type).and_return(rel)
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

          def all
            @relation ||= instance_double(ActiveRecord::Relation)
            allow(@relation).to receive(:to_a).and_return([])
            allow(@relation).to receive(:klass).and_return(self)
            allow(@relation).to receive(:class).and_return(ActiveRecord::Relation)
            allow(@relation).to receive(:balance_by_type).and_return(@relation)
            allow(@relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
            @relation
          end

          def where(*); end
        end
      end

      # Stub the constant rather than defining it directly
      stub_const('TestARModel', test_ar_model)

      # Mock ActiveRecord::Relation to include our module
      allow(ActiveRecord::Relation).to receive(:include).with(TypeBalancer::Rails::CollectionMethods)

      # Include our module to trigger the included hook
      test_ar_model.include(TypeBalancer::Rails::ActiveRecordExtension)

      allow(TestARModel).to receive(:where).and_return(relation)
    end

    it 'extends ActiveRecord::Relation with CollectionMethods' do
      expect(ActiveRecord::Relation).to have_received(:include).with(TypeBalancer::Rails::CollectionMethods)
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
