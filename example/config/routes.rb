Rails.application.routes.draw do
  resources :posts, only: [:index]

  get 'contents/balance_by_category', to: 'contents#balance_by_category', as: :balance_contents_by_category
  get 'contents/balance_by_content_type', to: 'contents#balance_by_content_type', as: :balance_contents_by_content_type

  root 'posts#index'
end
