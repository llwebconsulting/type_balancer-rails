require 'rails_helper'

RSpec.describe Post, type: :model do
  fixtures :posts

  it 'balances posts by media_type' do
    original = Post.order(:id).pluck(:media_type)
    balanced = Post.all.balance_by_type.pluck(:media_type)
    expect(balanced).not_to eq(original)
    expect(balanced.uniq.sort).to contain_exactly('article', 'image', 'video')
  end
end
