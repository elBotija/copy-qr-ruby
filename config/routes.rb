Rails.application.routes.draw do
  resources :memorials, only: %i[new create show edit update]

  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => 'rails/health#show', as: :rails_health_check

  namespace :admin do
    resources :promo, only: %i[index show create]
    resources :qr_codes, only: %i[new create]

    root 'dashboard#index'
  end

  # API para pagos
  namespace :api do
    namespace :v1 do
      match '/create-preference', to: 'payments#create_preference', via: %i[post options]
      post '/webhook', to: 'payments#webhook'
      get '/orders/:id', to: 'payments#order_status'
    end
  end

  # Defines the root path route ("/")
  root 'home#index'
end
