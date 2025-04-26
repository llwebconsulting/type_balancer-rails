# frozen_string_literal: true

module TypeBalancer
  module Rails
    class Railtie < ::Rails::Railtie
      initializer 'type_balancer.configure_rails_initialization' do
        # Include the ActiveRecord extension
        ActiveSupport.on_load(:active_record) do
          include TypeBalancer::Rails::ActiveRecordExtension
        end
      end
    end
  end
end
