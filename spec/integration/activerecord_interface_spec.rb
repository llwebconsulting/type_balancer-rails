# frozen_string_literal: true

require 'spec_helper'

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
    allow(klass).to receive(:where).with(id: [1, 2, 3]).and_return(rel)
    allow(rel).to receive(:order).with(:id).and_return(rel)
    allow(rel).to receive(:order).and_return(rel)
    allow(rel).to receive(:where).with(type: 'post').and_return(rel)
    rel.extend(TypeBalancer::Rails::CollectionMethods)
    rel
  end
  let(:ordered_relation) { relation }

  before do
    allow(TypeBalancer).to receive(:balance).and_return(records)
  end

  it 'preserves query interface while balancing' do
    expected_hashes = records.map { |r| { id: r.id, type: r.type } }
    expect(TypeBalancer).to receive(:balance).with(expected_hashes, type_field: :type)
    result = ordered_relation.balance_by_type(type_field: :type)
    expect(result).to respond_to(:where)
    expect(result).to respond_to(:order)
  end

  it 'maintains chainability after balancing' do
    result = ordered_relation.balance_by_type(type_field: :type)
    expect(result.where(type: 'post')).to respond_to(:order)
    expect(result.order(:title)).to respond_to(:where)
  end
end
