#!/usr/bin/env ruby
# /Users/carl/gems/type_balancer-rails/benchmarks/collection_methods_benchmark.rb

require 'bundler/setup'
require 'type_balancer'
require 'active_record'
require 'benchmark'
require_relative '../lib/type_balancer/rails'

# Setup in-memory SQLite DB and model
db_path = ':memory:'
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: db_path)

# Define a simple model for benchmarking
class Item < ActiveRecord::Base; end

# Create table and seed data
ActiveRecord::Schema.define do
  create_table :items, force: true do |t|
    t.string :media_type
  end
end

# Seed with N records, distributed across types
N = 20_000
types = ['video', 'article', 'podcast']
puts "Seeding #{N} records..."
N.times do |i|
  Item.create!(media_type: types[i % types.size])
end
puts 'Seeding complete.'

# Extend the relation with CollectionMethods
relation = Item.all.extending(TypeBalancer::Rails::CollectionMethods)

# Benchmark balance_by_type
puts "\nBenchmarking balance_by_type on #{N} records..."
Benchmark.bm(20) do |x|
  x.report('balance_by_type:') do
    result = relation.balance_by_type(type_field: :media_type)
    result.to_a
  end
end
