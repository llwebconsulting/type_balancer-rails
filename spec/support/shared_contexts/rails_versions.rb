# frozen_string_literal: true

RSpec.shared_context 'with Rails 7.0' do
  before do
    stub_const('Rails::VERSION::MAJOR', 7)
    stub_const('Rails::VERSION::MINOR', 0)
    stub_const('Rails::VERSION::STRING', '7.0.0')
  end
end

RSpec.shared_context 'with Rails 7.1' do
  before do
    stub_const('Rails::VERSION::MAJOR', 7)
    stub_const('Rails::VERSION::MINOR', 1)
    stub_const('Rails::VERSION::STRING', '7.1.0')
  end
end

RSpec.shared_context 'with Rails 8.0' do
  before do
    stub_const('Rails::VERSION::MAJOR', 8)
    stub_const('Rails::VERSION::MINOR', 0)
    stub_const('Rails::VERSION::STRING', '8.0.2')
  end
end
