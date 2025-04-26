# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  add_filter '/spec/'
  add_filter '/vendor/'
  minimum_coverage line: 80 # Set line coverage only since our branch coverage is low
end

require 'rspec'
require 'active_support'
require 'ostruct'

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'type_balancer_rails'
require 'type_balancer/rails/collection_methods'
require 'type_balancer/rails/active_record_extension'

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.order = :random
  config.seed = Kernel.rand(1_000_000)
end

# Test doubles for ActiveRecord-like behavior
class TestRelation
  include TypeBalancer::Rails::CollectionMethods
  include Enumerable

  attr_reader :records

  def initialize(records = [])
    @records = records
  end

  def where(*)
    self.class.new(@records)
  end

  def order(*)
    self.class.new(@records)
  end

  def to_a
    @records
  end

  def is_a?(klass)
    return true if klass == ActiveRecord::Relation

    super
  end

  def reorder(*)
    self
  end

  def none
    self.class.new([])
  end

  def klass
    TestModel
  end

  def select(*fields)
    return self if fields.empty?

    self.class.new(
      @records.map do |record|
        if fields.size == 1
          # For single field selection, return the full record
          record
        else
          # For multiple fields, create a new OpenStruct with selected fields
          selected_fields = fields.each_with_object({}) do |field, hash|
            hash[field] = record.send(field) if field.is_a?(Symbol) || field.is_a?(String)
          end
          OpenStruct.new(selected_fields)
        end
      end
    )
  end

  def table
    OpenStruct.new(name: 'test_table')
  end

  def limit(*)
    self.class.new(@records)
  end

  def offset(*)
    self.class.new(@records)
  end

  def each(&)
    @records.each(&)
  end

  def count
    @records.size
  end

  delegate :empty?, to: :@records
end

# Mock ActiveRecord::Base
module ActiveRecord
  class Base
    def self.all
      TestRelation.new([])
    end
  end
end

# Test model for specs
class TestModel < ActiveRecord::Base
  include TypeBalancer::Rails::ActiveRecordExtension

  class << self
    def all
      TestRelation.new(@test_records || [])
    end

    def where(conditions = {})
      records = @test_records || []
      if conditions[:id]
        ids = Array(conditions[:id])
        filtered = records.select { |r| ids.include?(r.id) }
        TestRelation.new(filtered)
      else
        TestRelation.new(records)
      end
    end

    def type_balancer_options
      @type_balancer_options ||= {}
    end

    attr_writer :type_balancer_options, :test_records
  end
end
