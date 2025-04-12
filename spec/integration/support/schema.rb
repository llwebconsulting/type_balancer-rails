# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    # Create test schema
    ActiveRecord::Schema.define do
      create_table :posts do |t|
        t.string :title
        t.string :media_type
        t.timestamps
      end

      create_table :type_balancer_balanced_positions do |t|
        t.references :record, polymorphic: true, null: false
        t.integer :position, null: false
        t.string :cache_key, null: false
        t.string :type_field
        t.timestamps

        t.index [:cache_key, :position], unique: true
        t.index [:record_type, :record_id, :cache_key], unique: true
      end
    end
  end

  config.after(:suite) do
    # Clean up database
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end
end 