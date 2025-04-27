class PostsController < ApplicationController
  def index
    @posts = Post.all.balance_by_type
  end
end
