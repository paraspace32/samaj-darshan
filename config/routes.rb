Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "manifest" => "pwa#manifest", as: :pwa_manifest
  get "service-worker" => "pwa#service_worker", as: :pwa_service_worker

  # Locale switching
  get "locale/:locale" => "locales#update", as: :set_locale

  # Authentication
  get  "login"  => "sessions#new",     as: :login
  post "login"  => "sessions#create"
  get  "logout" => "sessions#destroy", as: :logout
  get  "signup" => "registrations#new", as: :signup
  post "signup" => "registrations#create"

  # Admin
  namespace :admin do
    get "/" => "dashboard#show", as: :root
    resources :articles do
      member do
        patch :publish
        patch :approve
        patch :reject
        patch :submit_for_review
      end
    end
    resources :regions, except: [ :show, :new ] do
      member { patch :toggle_active }
    end
    resources :categories, except: [ :show, :new ] do
      member { patch :toggle_active }
    end
    resources :users, except: [ :show ] do
      member { patch :toggle_status }
    end
    resources :billboards, except: [ :show ] do
      member { patch :toggle_active }
    end
    resources :webinars do
      member do
        patch :publish
        patch :cancel
      end
    end
  end

  get "click/:id" => "billboard_clicks#show", as: :billboard_click

  # JSON API
  namespace :api do
    namespace :v1 do
      resources :articles, only: [ :index, :show ]
      resources :regions, only: [ :index, :show ]
      resources :categories, only: [ :index, :show ]

      namespace :admin do
        resources :articles do
          member do
            patch :publish
            patch :approve
            patch :reject
            patch :submit_for_review
          end
        end
        resources :regions do
          member { patch :toggle_active }
        end
        resources :categories do
          member { patch :toggle_active }
        end
        resources :users do
          member { patch :toggle_status }
        end
      end
    end
  end

  # Public news feed
  resources :articles, only: [ :index, :show ], param: :id do
    resources :comments, only: [ :create, :destroy ]
    resource :like, only: [] do
      post :toggle
    end
  end
  get "region/:slug" => "articles#index", as: :region_feed
  get "category/:slug" => "articles#index", as: :category_feed

  # Magazine
  get "magazine" => "magazine#index", as: :magazine
  get "magazine/:id" => "magazine#show", as: :magazine_article

  # Webinars
  resources :webinars, only: [:index, :show]

  get "offline" => "pages#offline"

  root "articles#index"
end
