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
    let(:video_post) { described_class.create!(title: 'Post 1', media_type: 'video') }
    let(:article_post) { described_class.create!(title: 'Post 2', media_type: 'article') }
    let(:another_video_post) { described_class.create!(title: 'Post 3', media_type: 'video') }

    before do
      TypeBalancer::Rails.clear_cache!
      described_class.delete_all
      video_post; article_post; another_video_post  # Create the records
    end

    after do
      described_class.delete_all
    end

    it 'works with basic ActiveRecord methods' do
      # Test .all
      balanced = described_class.all.balance_by_type
      expect(balanced.map(&:media_type)).to eq([ 'article', 'video', 'video' ])

      # Test .where
      videos = described_class.where(media_type: 'video').balance_by_type
      expect(videos.count).to eq(2)

      # Test .order
      ordered = described_class.order(:title).balance_by_type
      expect(ordered.map(&:title)).to contain_exactly('Post 1', 'Post 2', 'Post 3')
    end

    it 'works with reload' do
      post = video_post.reload
      expect(post.media_type).to eq('video')
    end

    it 'works with complex queries' do
      result = described_class.where(media_type: [ 'video', 'article' ])
                  .order(:title)
                  .limit(2)
                  .balance_by_type
      expect(result.length).to eq(2)
      expect(result.map(&:media_type)).to include('video', 'article')
    end
  end
end
