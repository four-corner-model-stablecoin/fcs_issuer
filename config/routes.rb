Rails.application.routes.draw do
  root 'home#index'
  
  get 'signup', to: 'users#new'
  post 'signup', to: 'users#create'
  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  resource :user, only: %i[show]
  resource :wallet, only: %i[show new create]
  resource :account, only: %i[show new create]
  resources :contracts, only: %i[new create]
  resources :stable_coins, only: %i[new create]

  post 'payment/create', to: 'payments#create'
  post 'payment/confirm', to: 'payments#confirm'

  post 'withdraw/create', to: 'withdraws#create'
  post 'withdraw/confirm', to: 'withdraws#confirm'
end
