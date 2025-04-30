# frozen_string_literal: true

require 'active_support/concern'

module TypeBalancer
  module Rails
    # Extension for ActiveRecord models to configure type balancing
    module ActiveRecordExtension
      extend ActiveSupport::Concern

      included do
        # TODO: Future Enhancement - Lazy Loading of CollectionMethods
        # Currently, CollectionMethods is included globally as soon as any model extends ActiveRecordExtension.
        # This could be optimized to only include CollectionMethods when balance_by_type is first called on a model.
        # This would make the extension truly opt-in at the model level and prevent unnecessary inclusion
        # in models that don't use type balancing.

        # Only include CollectionMethods if it hasn't been included yet
        unless ActiveRecord::Relation.included_modules.include?(TypeBalancer::Rails::CollectionMethods)
          ActiveRecord::Relation.include(TypeBalancer::Rails::CollectionMethods)
        end
      end

      class_methods do
        # Accepts either a symbol (type field) or options hash
        def balance_by_type(type_field = nil, **options)
          if type_field.is_a?(Hash)
            options = type_field
            type_field = options[:type_field]
          end

          self.type_balancer_options = {
            type_field: type_field || options[:type_field] || :type
          }

          return [] unless respond_to?(:all)

          relation = all
          return [] unless relation.is_a?(ActiveRecord::Relation)

          relation.balance_by_type(options)
        end

        def type_balancer_options
          @type_balancer_options ||= {}
        end

        attr_writer :type_balancer_options
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend TypeBalancer::Rails::ActiveRecordExtension
end
