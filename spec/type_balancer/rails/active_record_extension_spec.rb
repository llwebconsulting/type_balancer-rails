# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::ActiveRecordExtension, :unit do
  describe '.included' do
    let(:model_class) do
      Class.new(ActiveRecord::Base) do
        def self.all
          TestRelation.new([])
        end
      end
    end

    before do
      model_class.include(described_class)
    end

    it 'stores type field configuration' do
      model_class.balance_by_type type_field: :content_type
      expect(model_class.type_balancer_options[:type_field]).to eq(:content_type)
    end

    it 'uses default type field when none specified' do
      model_class.balance_by_type
      expect(model_class.type_balancer_options[:type_field]).to eq(:type)
    end

    it 'returns a relation with collection methods' do
      relation = model_class.balance_by_type
      expect(relation).to be_a(TestRelation)
      expect(relation).to respond_to(:balance_by_type)
    end
  end
end
