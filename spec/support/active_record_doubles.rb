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
      def ar_instance_double(class_name = 'ActiveRecord::Base')
        instance_double(class_name).tap do |double|
          # Common instance methods
          allow(double).to receive_messages(
            class: ar_class_double,
            save: true,
            save!: true,
            update: true,
            update!: true,
            destroy: true,
            destroy!: true,
            valid?: true,
            invalid?: false,
            persisted?: true,
            new_record?: false
          )

          # Callback methods
          allow(double).to receive(:run_callbacks).and_yield
          allow(double).to receive(:after_commit).and_yield
          allow(double).to receive(:before_commit).and_yield
        end
      end

      def ar_class_double(class_name = 'ActiveRecord::Base')
        class_double(class_name).tap do |double|
          setup_class_common_methods(double)
          setup_class_callback_methods(double)
        end
      end

      def ar_relation_double(class_name = 'ActiveRecord::Base')
        instance_double(ActiveRecord::Relation).tap do |double|
          setup_terminal_methods(double, class_name)
          setup_query_methods(double)
          setup_enumerable_methods(double, class_name)
        end
      end

      private

      def setup_terminal_methods(double, class_name)
        allow(double).to receive(:find_each).and_yield(ar_instance_double(class_name))
        allow(double).to receive(:find_in_batches).and_yield([ar_instance_double(class_name)])
      end

      def setup_query_methods(double)
        [:where, :order, :limit, :offset, :includes, :joins, :left_joins, :group, :having].each do |method|
          allow(double).to receive(method).and_return(double)
        end
      end

      def setup_enumerable_methods(double, class_name)
        allow(double).to receive_messages(
          first: ar_instance_double(class_name),
          last: ar_instance_double(class_name),
          count: 0,
          exists?: false,
          to_a: [ar_instance_double(class_name)],
          empty?: true,
          size: 0
        )
      end

      def setup_class_common_methods(double)
        allow(double).to receive_messages(
          table_name: 'test_table',
          primary_key: 'id',
          inheritance_column: 'type',
          find_by: ar_instance_double,
          find: ar_instance_double,
          create: ar_instance_double,
          create!: ar_instance_double
        )
      end

      def setup_class_callback_methods(double)
        [:after_commit, :before_commit, :after_save, :before_save].each do |callback|
          allow(double).to receive(callback)
        end
      end

      # Helper for including common ActiveRecord modules
      def ar_test_class(_class_name = 'TestModel')
        Class.new do
          include ActiveRecord::Callbacks
          include ActiveRecord::Validations

          def self.after_commit(*_args, &block)
            # Execute block immediately for testing
            block&.call(new) if block_given?
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
