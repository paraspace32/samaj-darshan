Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "manifest" => "pwa#manifest", as: :pwa_manifest
  get "service-worker" => "pwa#service_worker", as: :pwa_service_worker
  get "firebase-messaging-sw.js" => "pwa#firebase_messaging_sw", as: :firebase_messaging_sw

  # Push notifications
  resource :push_subscription, only: [ :create, :destroy ]
  post "push_subscription/log_error", to: "push_subscriptions#log_error", as: :push_subscription_log_error

  # Locale switching
  get "locale/:locale" => "locales#update", as: :set_locale
  get "set_region/:slug" => "locales#set_region", as: :set_region

  # Visit duration ping
  post "visit_ping" => "visits#ping"

  # Authentication (OTP-only via Firebase Phone Auth)
  get  "login" => "sessions#new",     as: :login
  post "login" => "sessions#create"
  post "login/set_name" => "sessions#set_name", as: :set_name
  delete "logout" => "sessions#destroy", as: :logout

  # User profile
  resource :profile, only: [ :edit, :update ], controller: "profiles"

  # Kanyadaan Yojna
  resources :kanyadaan_applications, only: [ :new, :create ], path: "kanyadaan"
  get "kanyadaan/success" => "kanyadaan_applications#success", as: :kanyadaan_success

  # Admin
  namespace :admin do
    get "/" => "dashboard#show", as: :root
    get "analytics" => "analytics#show", as: :analytics
    get "analytics/reports" => "analytics#reports", as: :analytics_reports
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
    resources :biodatas, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
      collection { get :search_users }
      member do
        patch :publish
        patch :reject
        patch :grant_consent
      end
    end
    resources :education_posts do
      member { patch :publish }
    end
    resources :job_posts do
      member { patch :publish }
    end

    get "cache/clear",     to: "cache#clear",     as: :clear_cache
    get "cache/ga_status", to: "cache#ga_status", as: :ga_status

    # Push notifications
    resources :push_notifications, only: [ :index ], path: "push_notifications" do
      collection { post :send_notification }
    end
    post "news/:news_id/push", to: "push_notifications#send_for_news", as: :news_push

    # Kanyadaan Yojna
    resources :kanyadaan_applications, only: [ :index, :show, :update ]

    # Tributes
    resources :tributes, except: [ :show ]
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
  get "shortlists", to: "shortlists#index", as: :shortlists
  resources :biodatas, only: [ :index, :show ] do
    member do
      get :template
      get :download_pdf
      post :shortlist
      delete :shortlist, action: :unshortlist
    end
  end
  resources :my_biodatas, only: [ :index, :new, :create, :edit, :update, :show ] do
    member do
      patch :submit_for_review
      patch :consent
      patch :decline_consent
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
  resources :jobs, only: [ :index, :show ] do
    resources :comments, only: [ :create, :destroy ], controller: "comments"
    resource :like, only: [], controller: "likes" do
      post :toggle
    end
  end

  # Tributes
  resources :tributes, only: [ :index, :show ] do
    collection { post :guest_flower }
    resource :flower, only: [ :create, :destroy ]
  end

  get "offline" => "pages#offline"

  root "news#index"
end
