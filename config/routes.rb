Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  resources :memorials, only: %i[new create show edit update] do
    member do
      get :verify_pin
      post :verify_pin, to: 'memorials#check_pin'
      get :attach_qr_form
      patch :attach_qr
    end
  end
  
  # Ruta especial para acceso por QR
  get '/memorial/:code', to: 'memorials#show_by_qr', as: 'memorial_by_qr'
  
  # Hacer explícita la configuración de Devise
  devise_for :users
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => 'rails/health#show', as: :rails_health_check

  namespace :admin do
    resources :email_templates, only: [:index] do
      member do
        get :preview
        post :test
      end
    end
    resources :invoices, only: [:new, :create, :destroy] do
      collection do
        get :download
      end
    end
    resources :orders do
      member do
        post :send_tracking
        post :send_invoice
        get :shipping
        patch :shipping, to: "orders#update"
      end
    end
    resources :promo, only: %i[index show create]
    resources :qr_codes, only: %i[index new create] do
      member do
        post :release
      end
    end

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