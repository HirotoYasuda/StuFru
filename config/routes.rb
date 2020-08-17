Rails.application.routes.draw do
  get 'search/users', to: 'search#users', as: 'search'
  get '/microposts', to: 'microposts#new'
  get '/microposts/:id/comments', to: 'microposts#show'
  get 'home/home', to: 'home#home', as: 'home'
  get '/my_page/:id', to: 'users#my_page', as: 'my_page'
  devise_for :users
  root 'home#top'
  resources :users, only: [:index, :show, :update] do
    member do
      get :follow
    end
  end
  resources :books, only: [:index, :create, :show, :update]
  resources :book_registers, only: [:create, :destroy]
  resources :microposts, except: [:index] do
    resources :likes, only: [:create, :destroy]
    resources :comments, only: [:create, :destroy]
  end
  resources :relationships, only: [:create, :destroy]
end
