require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  fixtures :posts

  describe 'GET #index' do
    it 'assigns a balanced set of posts to @posts' do
      get :index
      expect(assigns(:posts)).to be_present
      original = Post.order(:id).pluck(:media_type)
      balanced = assigns(:posts).pluck(:media_type)
      expect(balanced).not_to eq(original)
      expect(balanced.uniq.sort).to contain_exactly('article', 'image', 'video')
    end
  end
end
