# frozen_string_literal: true

require 'active_record'

# Set up in-memory SQLite database for testing
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

# Create test table
ActiveRecord::Schema.define do
  create_table :test_models, force: true do |t|
    t.integer :category
    t.timestamps
  end
end

# Define test model
class TestModel < ActiveRecord::Base
  enum category: { a: 0, b: 1, c: 2 }
  include TypeBalancer::Rails::ActiveRecordExtension
  balance_by_type type_field: :category
end
