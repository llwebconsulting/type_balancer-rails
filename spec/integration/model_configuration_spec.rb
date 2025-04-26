# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Model Configuration', :integration do
  let(:records) do
    [
      OpenStruct.new(id: 1, type: 'post', title: 'First Post'),
      OpenStruct.new(id: 2, type: 'video', title: 'First Video'),
      OpenStruct.new(id: 3, type: 'post', title: 'Second Post')
    ]
  end

  let(:relation) { TestRelation.new(records) }

  before do
    allow(TypeBalancer).to receive(:balance).and_return(records)

    # define TestModel using stub_const to avoid remove_const and constant-in-block offenses  # changed
    test_class = Class.new(ActiveRecord::Base) do
      include TypeBalancer::Rails::ActiveRecordExtension

      balance_by_type type_field: :type

      class << self
        attr_accessor :test_records

        def all
          TestRelation.new(test_records)
        end
      end
    end
    stub_const('TestModel', test_class) # changed
    TestModel.test_records = records # changed
  end

  it 'uses model-level configuration' do
    expect(TypeBalancer).to receive(:balance).with(
      records,
      type_field: :type
    )

    TestModel.all.balance_by_type
  end

  it 'allows overriding model configuration per-query' do
    expect(TypeBalancer).to receive(:balance).with(
      records,
      type_field: :category
    )

    TestModel.all.balance_by_type(type_field: :category)
  end
end
