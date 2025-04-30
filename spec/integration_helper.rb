# frozen_string_literal: true

require 'spec_helper'

# Shared context for integration tests
RSpec.shared_context 'with integration setup' do
  let(:records) do
    [
      OpenStruct.new(id: 1, type: 'post', title: 'First Post'),
      OpenStruct.new(id: 2, type: 'video', title: 'First Video'),
      OpenStruct.new(id: 3, type: 'post', title: 'Second Post')
    ]
  end

  before do
    allow(TypeBalancer).to receive(:balance).and_return(records)
  end
end

RSpec.configure do |config|
  config.include_context 'with integration setup', type: :integration
end
