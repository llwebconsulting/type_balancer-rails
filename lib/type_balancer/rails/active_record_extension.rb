# frozen_string_literal: true

module TypeBalancer
  module Rails
    module ActiveRecordExtension
      extend ActiveSupport::Concern

      included do
        class_attribute :type_balancer_options, instance_writer: false
      end

      module ClassMethods
        def balance_by_type(options = {})
          self.type_balancer_options = options.dup.freeze
          include TypeBalancer::Rails::CacheInvalidation
          include TypeBalancer::Rails::TypeBalancerCollection
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  extend TypeBalancer::Rails::ActiveRecordExtension
end
