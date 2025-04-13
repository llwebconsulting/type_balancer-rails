# frozen_string_literal: true

require 'rails/generators'

module TypeBalancer
  module Generators
    # Generator for installing TypeBalancer::Rails
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def create_initializer
        template(
          'type_balancer.rb.erb',
          'config/initializers/type_balancer.rb'
        )
      end
    end
  end
end
