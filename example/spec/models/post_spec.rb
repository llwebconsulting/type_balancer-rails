require 'rails_helper'

RSpec.describe Post, type: :model do
  fixtures :posts

  it 'balances posts by media_type' do
    original = described_class.order(:id).pluck(:media_type)
    balanced = described_class.all.balance_by_type(type_field: :media_type).pluck(:media_type)
    expect(balanced).not_to eq(original)
    expect(balanced.uniq.sort).to contain_exactly('article', 'image', 'video')
  end

  describe 'type balancing with real records' do
    before do
      Post.delete_all
      @post1 = Post.create!(title: 'Post 1', media_type: 'video')
      @post2 = Post.create!(title: 'Post 2', media_type: 'article')
      @post3 = Post.create!(title: 'Post 3', media_type: 'video')
    end

    after do
      Post.delete_all
    end

    it 'works with basic ActiveRecord methods' do
      # Test .all
      balanced = Post.all.balance_by_type
      expect(balanced.map(&:media_type)).to eq(['article', 'video', 'video'])

      # Test .where
      videos = Post.where(media_type: 'video').balance_by_type
      expect(videos.count).to eq(2)

      # Test .order
      ordered = Post.order(:title).balance_by_type
      expect(ordered.map(&:title)).to match_array(['Post 1', 'Post 2', 'Post 3'])
    end

    it 'works with reload' do
      post = @post1.reload
      expect(post.media_type).to eq('video')
    end

    it 'works with complex queries' do
      result = Post.where(media_type: ['video', 'article'])
                  .order(:title)
                  .limit(2)
                  .balance_by_type
      expect(result.length).to eq(2)
      expect(result.map(&:media_type)).to include('video', 'article')
    end
  end
end
