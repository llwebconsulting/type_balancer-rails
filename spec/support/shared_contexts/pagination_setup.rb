RSpec.shared_context 'with pagination setup' do
  let(:collection) { double('ActiveRecord::Relation') }
  let(:cursor_strategy) { double('CursorStrategy') }
  let(:options) { { cursor_strategy: cursor_strategy } }
  let(:prev_page) { nil }
  let(:scope) { collection }
  let(:total_count) { 100 }
  let(:items_per_page) { 25 }
  let(:current_page) { 1 }

  before do
    allow(collection).to receive_messages(
      total_count: total_count,
      limit: collection,
      offset: collection,
      to_a: []
    )
  end
end

RSpec.shared_context 'with cursor pagination' do
  include_context 'with pagination setup'

  let(:cursor_service) { instance_double(TypeBalancer::Rails::Query::CursorService) }

  before do
    allow(TypeBalancer::Rails::Query::CursorService).to receive(:new)
      .with(collection, cursor_strategy)
      .and_return(cursor_service)
    allow(cursor_service).to receive_messages(
      paginate: collection,
      total_count: total_count,
      next_page: nil,
      prev_page: prev_page
    )
  end
end
