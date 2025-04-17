RSpec.shared_examples 'pagination behavior' do
  it 'returns paginated data with metadata' do
    result = subject.paginate(scope, options)

    expect(result).to be_a(Hash)
    expect(result[:data]).to eq([])
    expect(result[:metadata]).to include(
      total_count: total_count,
      next_page: nil,
      prev_page: prev_page,
      current_page: current_page,
      items_per_page: items_per_page
    )
  end

  context 'when an error occurs during pagination' do
    before do
      allow(collection).to receive(:total_count)
        .and_raise(StandardError, 'Pagination failed')
    end

    it 'raises a PaginationError' do
      expect do
        subject.paginate(scope, options)
      end.to raise_error(TypeBalancer::Rails::Errors::PaginationError, 'Pagination failed')
    end
  end
end

RSpec.shared_examples 'cursor pagination behavior' do
  it_behaves_like 'pagination behavior'

  context 'when cursor service is used' do
    it 'delegates pagination to cursor service' do
      subject.paginate(scope, options)

      expect(TypeBalancer::Rails::Query::CursorService)
        .to have_received(:new)
        .with(collection, cursor_strategy)
      expect(cursor_service).to have_received(:paginate)
    end

    it 'retrieves metadata from cursor service' do
      subject.paginate(scope, options)

      expect(cursor_service).to have_received(:total_count)
      expect(cursor_service).to have_received(:next_page)
      expect(cursor_service).to have_received(:prev_page)
    end
  end
end
