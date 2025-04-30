require 'rails_helper'

RSpec.describe Content, type: :model do
  fixtures :contents

  it 'balances contents by category' do
    original = described_class.order(:id).pluck(:category)
    balanced = described_class.all.balance_by_type(type_field: :category).pluck(:category)
    expect(balanced).not_to eq(original)
    expect(balanced.uniq.sort).to contain_exactly('blog', 'news', 'tutorial')
  end

  it 'balances contents by content_type' do
    original = described_class.order(:id).pluck(:content_type)
    balanced = described_class.all.balance_by_type(type_field: :content_type).pluck(:content_type)
    expect(balanced).not_to eq(original)
    expect(balanced.uniq.sort).to contain_exactly('article', 'image', 'video')
  end
end
