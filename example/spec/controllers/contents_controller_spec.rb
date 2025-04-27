require 'rails_helper'

RSpec.describe ContentsController, type: :controller do
  fixtures :contents

  describe 'GET #balance_by_category' do
    it 'assigns a balanced set of contents by category to @contents' do
      get :balance_by_category
      expect(assigns(:contents)).to be_present
      original = Content.order(:id).pluck(:category)
      balanced = assigns(:contents).pluck(:category)
      expect(balanced).not_to eq(original)
      expect(balanced.uniq.sort).to contain_exactly('blog', 'news', 'tutorial')
    end
  end

  describe 'GET #balance_by_content_type' do
    it 'assigns a balanced set of contents by content_type to @contents' do
      get :balance_by_content_type
      expect(assigns(:contents)).to be_present
      original = Content.order(:id).pluck(:content_type)
      balanced = assigns(:contents).pluck(:content_type)
      expect(balanced).not_to eq(original)
      expect(balanced.uniq.sort).to contain_exactly('article', 'image', 'video')
    end
  end
end
