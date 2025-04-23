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

  let(:relation) { TestRelation.new(records) }
  let(:ordered_relation) { relation.order(:id) }

  before do
    allow(TypeBalancer).to receive(:balance).and_return(records)
  end

  it 'preserves query interface while balancing' do
    expect(TypeBalancer).to receive(:balance).with(records, type_field: :type)
    result = ordered_relation.balance_by_type(type_field: :type)
    expect(result).to be_a(TestRelation)
    expect(result).to respond_to(:where)
    expect(result).to respond_to(:order)
  end

  it 'maintains chainability after balancing' do
    result = ordered_relation.balance_by_type(type_field: :type)
    expect(result.where(type: 'post')).to be_a(TestRelation)
    expect(result.order(:title)).to be_a(TestRelation)
  end
end
