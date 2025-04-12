# frozen_string_literal: true

RSpec.shared_context 'with nil expectations allowed' do
  before do
    RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
  end

  after do
    RSpec::Mocks.configuration.allow_message_expectations_on_nil = false
  end
end
