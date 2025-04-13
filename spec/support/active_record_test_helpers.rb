# frozen_string_literal: true

module ActiveRecordTestHelpers
  def ar_test_class
    Class.new do
      include ActiveModel::Model
      extend ActiveModel::Naming

      def self.model_name
        ActiveModel::Name.new(self, nil, 'TestModel')
      end

      def self.primary_key
        'id'
      end

      def self.base_class
        self
      end
    end
  end

  def ar_relation_double
    instance_double('ActiveRecord::Relation').tap do |double|
      allow(double).to receive(:is_a?).with(any_args).and_return(false)
      allow(double).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
      allow(double).to receive(:klass).and_return(ar_test_class)
      allow(double).to receive(:where).and_return(double)
      allow(double).to receive(:order).and_return(double)
      allow(double).to receive(:pluck).and_return([])
      allow(double).to receive(:find).and_return(nil)
    end
  end

  def ar_instance_double
    instance_double('ActiveRecord::Base').tap do |double|
      allow(double).to receive(:is_a?).with(any_args).and_return(false)
      allow(double).to receive(:is_a?).with(ActiveRecord::Base).and_return(true)
      allow(double).to receive(:id).and_return(1)
    end
  end
end

RSpec.configure do |config|
  config.include ActiveRecordTestHelpers
end 