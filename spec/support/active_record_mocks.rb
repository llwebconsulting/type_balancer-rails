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
          klass: model_class,
          to_a: records,
          each: records.each,
          map: records.map,
          find_each: records.each,
          pluck: records.map(&:id),
          update_all: records.length,
          transaction: ->(block) { block.call }
        ).tap do |relation|
          allow(relation).to receive(:is_a?).with(any_args).and_return(false)
          allow(relation).to receive(:is_a?).with(ActiveRecord::Relation).and_return(true)
          allow(relation).to receive(:klass).and_return(model_class)
        end
      end

      def mock_model_class(name)
        klass = Class.new do
          extend ActiveModel::Naming
          include ActiveModel::Model
          include ActiveModel::Callbacks

          define_model_callbacks :commit

          class << self
            attr_accessor :_model_name

            def name
              _model_name
            end

            def base_class
              self
            end

            def primary_key
              'id'
            end

            def table_name
              model_name.plural
            end

            def after_commit(*args, &block)
              set_callback(:commit, :after, *args, &block)
            end

            def model_name
              @model_name ||= begin
                model_name = ActiveModel::Name.new(self, nil, _model_name)
                def model_name.plural
                  @plural ||= ActiveSupport::Inflector.pluralize(self.name.underscore)
                end
                model_name
              end
            end
          end

          attr_accessor :id
        end

        klass._model_name = name
        stub_const(name, klass)
        klass
      end
    end
  end
end

RSpec.configure do |config|
  config.include TypeBalancer::TestHelpers::ActiveRecordTestClasses
end
