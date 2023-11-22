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
  resources :account_transactions, only: %i[index]
  resources :wallet_transactions, only: %i[index]
  resources :issuance_transactions, only: %i[index]
  resources :payment_transactions, only: %i[index]
  resources :withdrawal_transactions, only: %i[index]

  namespace :api do
    post 'payment/create', to: 'payments#create'
    post 'payment/confirm', to: 'payments#confirm'

    post 'withdraw/create', to: 'withdraws#create'
    post 'withdraw/confirm', to: 'withdraws#confirm'

    resources :issuance_requests, only: %i[show]
    resources :payment_requests, only: %i[show]
    resources :withdrawal_requests, only: %i[show]
  end
end
