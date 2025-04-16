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
      module MockModelClassMethods
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

        def after_commit(*, &)
          set_callback(:commit, :after, *, &)
        end

        def model_name
          @model_name ||= begin
            model_name = ActiveModel::Name.new(self, nil, _model_name)
            def model_name.plural
              @plural ||= ActiveSupport::Inflector.pluralize(name.underscore)
            end
            model_name
          end
        end
      end

      class MockModelBase
        extend ActiveModel::Naming
        include ActiveModel::Model
        include ActiveModel::Callbacks

        define_model_callbacks :commit

        class << self
          attr_accessor :_model_name
        end

        attr_accessor :id
      end

      def mock_model_class(name)
        klass = Class.new(MockModelBase)
        klass.singleton_class.include(MockModelClassMethods)
        klass._model_name = name
        stub_const(name, klass)
        klass
      end

      private

      def setup_relation_basics(mock_relation, model_class, records)
        allow(mock_relation).to receive_messages(
          to_a: records,
          empty?: records.empty?,
          size: records.size,
          count: records.size,
          klass: model_class,
          is_a?: ->(klass) { klass == ActiveRecord::Relation }
        )
      end

      def setup_relation_queries(mock_relation, records, &)
        allow(mock_relation).to receive_messages(
          find_each: records.each(&),
          find_in_batches: records.each(&),
          first: records.first,
          last: records.last
        )

        [:where, :order, :limit, :offset, :includes, :joins, :left_joins, :group, :having].each do |method|
          allow(mock_relation).to receive(method).and_return(mock_relation)
        end
      end

      def setup_relation_enumerables(mock_relation, records, &)
        allow(mock_relation).to receive_messages(
          each: records.each(&),
          map: records.map(&),
          select: records.select(&),
          reject: records.reject(&)
        )
      end

      def mock_active_record_relation(model_class, records = [])
        mock_relation = instance_double(ActiveRecord::Relation)
        setup_relation_basics(mock_relation, model_class, records)
        setup_relation_queries(mock_relation, records)
        setup_relation_enumerables(mock_relation, records)
        mock_relation
      end
    end
  end
end

RSpec.configure do |config|
  config.include TypeBalancer::TestHelpers::ActiveRecordTestClasses
end
