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

  describe 'type balancing with real records' do
    before do
      TypeBalancer::Rails.clear_cache!
      described_class.delete_all
      @content1 = described_class.create!(title: 'Content 1', content_type: 'blog')
      @content2 = described_class.create!(title: 'Content 2', content_type: 'news')
      @content3 = described_class.create!(title: 'Content 3', content_type: 'blog')
    end

    after do
      described_class.delete_all
    end

    it 'works with dynamic type field configuration' do
      # Test with content_type field
      balanced = described_class.all.balance_by_type(type_field: :content_type)
      expect(balanced.map(&:content_type)).to eq([ 'news', 'blog', 'blog' ])

      # Test with where clause
      blogs = described_class.where(content_type: 'blog').balance_by_type(type_field: :content_type)
      expect(blogs.count).to eq(2)
    end

    it 'works with complex queries and dynamic type field' do
      result = described_class.where(content_type: [ 'blog', 'news' ])
                     .order(:title)
                     .limit(2)
                     .balance_by_type(type_field: :content_type)
      expect(result.length).to eq(2)
      expect(result.map(&:content_type)).to include('blog', 'news')
    end
  end
end
