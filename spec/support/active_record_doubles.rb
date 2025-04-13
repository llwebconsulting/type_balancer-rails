# frozen_string_literal: true

# This file provides test doubles for ActiveRecord classes and instances.
# Use these doubles when you want to:
# - Mock ActiveRecord behavior without actual implementation
# - Verify method calls and responses
# - Test interface compliance
# - Need predefined responses for common AR methods
#
# For cases where you need actual ActiveRecord-like behavior (e.g., callbacks, naming),
# use the helpers in active_record_test_classes.rb instead.

module TypeBalancer
  module TestHelpers
    module ActiveRecordDoubles
      def ar_instance_double(class_name = "ActiveRecord::Base")
        instance_double(class_name).tap do |double|
          # Common instance methods
          allow(double).to receive(:class).and_return(ar_class_double)
          allow(double).to receive(:save).and_return(true)
          allow(double).to receive(:save!).and_return(true)
          allow(double).to receive(:update).and_return(true)
          allow(double).to receive(:update!).and_return(true)
          allow(double).to receive(:destroy).and_return(true)
          allow(double).to receive(:destroy!).and_return(true)
          allow(double).to receive(:valid?).and_return(true)
          allow(double).to receive(:invalid?).and_return(false)
          allow(double).to receive(:persisted?).and_return(true)
          allow(double).to receive(:new_record?).and_return(false)
          
          # Callback methods
          allow(double).to receive(:run_callbacks).and_yield
          allow(double).to receive(:after_commit).and_yield
          allow(double).to receive(:before_commit).and_yield
        end
      end

      def ar_class_double(class_name = "ActiveRecord::Base")
        class_double(class_name).tap do |double|
          # Common class methods
          allow(double).to receive(:table_name).and_return("test_table")
          allow(double).to receive(:primary_key).and_return("id")
          allow(double).to receive(:inheritance_column).and_return("type")
          allow(double).to receive(:find_by).and_return(ar_instance_double)
          allow(double).to receive(:find).and_return(ar_instance_double)
          allow(double).to receive(:create).and_return(ar_instance_double)
          allow(double).to receive(:create!).and_return(ar_instance_double)
          
          # Callback registration methods
          allow(double).to receive(:after_commit)
          allow(double).to receive(:before_commit)
          allow(double).to receive(:after_save)
          allow(double).to receive(:before_save)
        end
      end

      def ar_relation_double(class_name = "ActiveRecord::Base")
        instance_double("ActiveRecord::Relation").tap do |double|
          # Common scope/query methods
          allow(double).to receive(:where).and_return(double)
          allow(double).to receive(:order).and_return(double)
          allow(double).to receive(:limit).and_return(double)
          allow(double).to receive(:offset).and_return(double)
          allow(double).to receive(:includes).and_return(double)
          allow(double).to receive(:joins).and_return(double)
          allow(double).to receive(:left_joins).and_return(double)
          allow(double).to receive(:group).and_return(double)
          allow(double).to receive(:having).and_return(double)
          
          # Terminal methods
          allow(double).to receive(:first).and_return(ar_instance_double(class_name))
          allow(double).to receive(:last).and_return(ar_instance_double(class_name))
          allow(double).to receive(:find_each).and_yield(ar_instance_double(class_name))
          allow(double).to receive(:find_in_batches).and_yield([ar_instance_double(class_name)])
          allow(double).to receive(:count).and_return(0)
          allow(double).to receive(:exists?).and_return(false)
          
          # Enumerable methods
          allow(double).to receive(:to_a).and_return([ar_instance_double(class_name)])
          allow(double).to receive(:empty?).and_return(true)
          allow(double).to receive(:size).and_return(0)
        end
      end

      # Helper for including common ActiveRecord modules
      def ar_test_class(class_name = "TestModel")
        Class.new do
          include ActiveRecord::Callbacks
          include ActiveRecord::Validations

          def self.after_commit(*args, &block)
            # Execute block immediately for testing
            block&.call(self.new) if block_given?
          end

          def self.name
            class_name
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include TypeBalancer::TestHelpers::ActiveRecordDoubles
end 