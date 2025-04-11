# frozen_string_literal: true

require "rails/generators"
require "rails/generators/migration"

module TypeBalancer
  module Generators
    # Generator for installing TypeBalancer::Rails
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      def self.next_migration_number(path)
        next_migration_number = current_migration_number(path) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def create_migration_file
        migration_template(
          "create_type_balancer_balanced_positions.rb.erb",
          "db/migrate/create_type_balancer_balanced_positions.rb"
        )
      end

      def create_initializer
        template(
          "type_balancer.rb.erb",
          "config/initializers/type_balancer.rb"
        )
      end
    end
  end
end 