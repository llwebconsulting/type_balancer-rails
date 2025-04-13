# frozen_string_literal: true

# This file provides actual class implementations that mimic ActiveRecord behavior.
# Use these classes when you need:
# - Real ActiveRecord-like behavior (callbacks, naming, etc.)
# - To test module inclusion
# - To work with actual record arrays
# - To test behavior that depends on ActiveRecord's class hierarchy
#
# For simple method stubbing and interface verification,
# use the doubles in active_record_doubles.rb instead.

module TypeBalancer
  module TestHelpers
    module ActiveRecordTestClasses
      def mock_active_record_relation(model_class, records = [])
        instance_double(
          ActiveRecord::Relation,
          model_name: model_class.model_name,
          to_a: records,
          each: records.each,
          map: records.map,
          find_each: records.each,
          pluck: records.map(&:id),
          update_all: records.length,
          transaction: ->(block) { block.call }
        )
      end

      def mock_model_class(name)
        klass = Class.new do
          extend ActiveModel::Naming
          include ActiveModel::Model
          include ActiveModel::Callbacks

          define_model_callbacks :commit

          def self.name
            name
          end

          def self.base_class
            self
          end

          def self.primary_key
            'id'
          end

          def self.table_name
            name.underscore.pluralize
          end

          def self.after_commit(*args, &block)
            set_callback(:commit, :after, *args, &block)
          end

          attr_accessor :id
        end

        stub_const(name, klass)
        klass
      end
    end
  end
end

RSpec.configure do |config|
  config.include TypeBalancer::TestHelpers::ActiveRecordTestClasses
end
