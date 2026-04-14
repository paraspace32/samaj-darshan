Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "manifest" => "pwa#manifest", as: :pwa_manifest
  get "service-worker" => "pwa#service_worker", as: :pwa_service_worker

  # Locale switching
  get "locale/:locale" => "locales#update", as: :set_locale

  # Authentication
  get  "login" => "sessions#new",     as: :login
  post "login" => "sessions#create"
  get  "logout" => "sessions#destroy", as: :logout
  get  "signup" => "registrations#new", as: :signup
  post "signup" => "registrations#create"

  # Admin
  namespace :admin do
    get "/" => "dashboard#show", as: :root
    resources :news do
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
    resources :magazines do
      member { patch :publish }
      resources :magazine_articles, except: [ :index, :show ]
    end
    resources :webinars do
      member do
        patch :publish
        patch :cancel
      end
    end
    resources :biodatas, only: [ :index, :show, :destroy ] do
      member do
        patch :publish
        patch :reject
      end
    end
    resources :education_posts do
      member { patch :publish }
    end
    resources :job_posts do
      member { patch :publish }
    end
  end

  get "click/:id" => "billboard_clicks#show", as: :billboard_click

  # JSON API
  namespace :api do
    namespace :v1 do
      resources :news, only: [ :index, :show ]
      resources :regions, only: [ :index, :show ]
      resources :categories, only: [ :index, :show ]

      namespace :admin do
        resources :news do
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
  resources :news, only: [ :index, :show ], param: :id do
    resources :comments, only: [ :create, :destroy ]
    resource :like, only: [] do
      post :toggle
    end
  end
  get "region/:slug" => "news#index", as: :region_feed
  get "category/:slug" => "news#index", as: :category_feed

  # Magazines
  resources :magazines, only: [ :index, :show ]

  # Webinars
  resources :webinars, only: [ :index, :show ]

  # Marriage Section / Biodata
  resources :biodatas, only: [ :index, :show ] do
    member do
      get :template
      get :download_pdf
    end
  end
  resource :my_biodata, controller: :my_biodatas, only: [ :new, :create, :edit, :update, :show ] do
    member do
      patch :submit_for_review
      get :template
      get :download_pdf
    end
  end

  # Education
  resources :education, only: [ :index, :show ], controller: "education" do
    resources :comments, only: [ :create, :destroy ], controller: "comments"
    resource :like, only: [], controller: "likes" do
      post :toggle
    end
  end

  # Jobs
  resources :jobs, only: [ :index, :show ]

  get "offline" => "pages#offline"

  root "news#index"
end
