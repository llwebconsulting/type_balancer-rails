# frozen_string_literal: true

module TypeBalancer
  module Rails
    # Stores balanced positions for records in a collection
    class BalancedPosition < ::ActiveRecord::Base
      self.table_name = 'type_balancer_balanced_positions'

      belongs_to :record, polymorphic: true

      validates :record, presence: true
      validates :position, presence: true
      validates :cache_key, presence: true
      validates :position, uniqueness: { scope: :cache_key }
      validates :record_id, uniqueness: { scope: %i[record_type cache_key] }

      scope :for_collection, ->(cache_key) { where(cache_key: cache_key).order(:position) }
      scope :for_record, ->(record) { where(record: record) }

      class << self
        def table_definition
          proc do |t|
            t.references :record, polymorphic: true, null: false
            t.integer :position, null: false
            t.string :cache_key, null: false
            t.string :type_field
            t.timestamps

            t.index %i[cache_key position], unique: true
            t.index %i[record_type record_id cache_key], unique: true
          end
        end
      end
    end
  end
end
