# frozen_string_literal: true

require 'spec_helper'

# We're using string references for class_double and instance_double of 'MyModel'
# throughout this file because it's a non-existent class used only for testing the interface
# rubocop:disable RSpec/VerifiedDoubleReference
RSpec.describe 'ActiveRecord Interface', :integration do
  let(:records) do
    [
      OpenStruct.new(id: 1, type: 'post', title: 'First Post'),
      OpenStruct.new(id: 2, type: 'video', title: 'First Video'),
      OpenStruct.new(id: 3, type: 'post', title: 'Second Post')
    ]
  end

  let(:klass) { class_double('MyModel', name: 'MyModel') }
  let(:relation) do
    rel = instance_double(ActiveRecord::Relation)
    allow(rel).to receive(:to_a).and_return(records)
    allow(rel).to receive(:klass).and_return(klass)
    allow(rel).to receive(:class).and_return(ActiveRecord::Relation)
    allow(klass).to receive(:name).and_return('MyModel')
    allow(klass).to receive(:where) do |*args|
      if args.empty? || !args.first.is_a?(Hash) || !args.first.key?(:id)
        rel
      else
        ids = args.first[:id]
        relation_double_with_map(records.select { |r| ids.include?(r.id) })
      end
    end
    allow(rel).to receive(:order).with(:id).and_return(rel)
    allow(rel).to receive(:order).with(any_args).and_return(rel)
    allow(rel).to receive(:where).with(type: 'post').and_return(rel)
    allow(rel).to receive(:to_sql).and_return('SELECT * FROM my_models')
    allow(rel).to receive(:select) { |*_args| rel }
    allow(rel).to receive(:map) do |&block|
      if block
        records.map { |r| block.call(r) }
      else
        records.map
      end
    end
    rel.extend(TypeBalancer::Rails::CollectionMethods)
    rel
  end
  let(:ordered_relation) { relation }

  before do
    RSpec::Mocks.space.proxy_for(TypeBalancer).reset
    # Assign a fresh cache adapter for each test to prevent shared state
    cache = Class.new do
      def initialize = @store = {}

      def fetch(key, _options = {})
        @store[key] ||= yield
      end

      def clear = @store.clear
    end.new
    allow(TypeBalancer::Rails).to receive(:cache_adapter).and_return(cache)
  end

  it 'preserves query interface while balancing' do
    expected_hashes = records.map { |r| { id: r.id, type: r.type } }
    allow(TypeBalancer).to receive(:balance).and_wrap_original do |m, *args|
      puts "TypeBalancer.balance called with: #{args.inspect}"
      m.call(*args)
    end
    expect(TypeBalancer).to receive(:balance).with(
      satisfy { |actual| records_match_expected?(actual, expected_hashes) },
      type_field: :type,
      type_order: ['video', 'post']
    ).and_call_original
    result = ordered_relation.balance_by_type(type_field: :type)
    expect(result).to respond_to(:where)
    expect(result).to respond_to(:order)
  end

  it 'maintains chainability after balancing' do
    allow(TypeBalancer).to receive(:balance).and_return(records)
    result = ordered_relation.balance_by_type(type_field: :type)
    expect(result.where(type: 'post')).to respond_to(:order)
    expect(result.order(:title)).to respond_to(:where)
  end

  # Helper to mimic an ActiveRecord relation for a given set of records
  # Provides chainable stubs for where, order, and map
  # Used to simulate filtered relations in the test
  private

  def relation_double_with_map(records)
    rel = instance_double(ActiveRecord::Relation)
    allow(rel).to receive(:to_a).and_return(records)
    allow(rel).to receive(:klass).and_return(klass)
    allow(rel).to receive(:class).and_return(ActiveRecord::Relation)
    allow(rel).to receive(:where) { rel }
    allow(rel).to receive(:order) { rel }
    allow(rel).to receive(:map) do |&block|
      if block
        records.map { |r| block.call(r) }
      else
        records.map
      end
    end
    rel
  end

  def records_match_expected?(actual, expected)
    actual.map do |r|
      if r.respond_to?(:id) && r.respond_to?(:type)
        { id: r.id, type: r.type }
      else
        { id: r[:id], type: r[:type] }
      end
    end == expected
  end
end
# rubocop:enable RSpec/VerifiedDoubleReference
