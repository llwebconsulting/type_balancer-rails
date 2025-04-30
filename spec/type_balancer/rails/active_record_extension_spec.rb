# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TypeBalancer::Rails::ActiveRecordExtension, :unit do
  describe '.included' do
    before do
      # Create a fake ActiveRecord::Relation class
      fake_relation = Class.new do
        include TypeBalancer::Rails::CollectionMethods
      end
      stub_const('ActiveRecord::Relation', fake_relation)
    end

    it 'extends ActiveRecord::Relation with CollectionMethods' do
      expect(ActiveRecord::Relation.included_modules).to include(TypeBalancer::Rails::CollectionMethods)
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
