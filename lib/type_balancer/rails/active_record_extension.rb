# frozen_string_literal: true

require 'active_support/concern'

module TypeBalancer
  module Rails
    # Extension for ActiveRecord models to configure type balancing
    module ActiveRecordExtension
      extend ActiveSupport::Concern

      included do
        class << self
          def all
            relation = super
            relation.extend(TypeBalancer::Rails::CollectionMethods)
            relation
          end
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

          relation.extend(CollectionMethods)
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
