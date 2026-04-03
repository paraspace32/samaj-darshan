require "rails_helper"

RSpec.describe "Routes", type: :routing do
  describe "authentication" do
    it { expect(get: "/login").to route_to("sessions#new") }
    it { expect(post: "/login").to route_to("sessions#create") }
    it { expect(get: "/logout").to route_to("sessions#destroy") }
    it { expect(get: "/signup").to route_to("registrations#new") }
    it { expect(post: "/signup").to route_to("registrations#create") }
  end

  describe "locale" do
    it { expect(get: "/locale/hi").to route_to("locales#update", locale: "hi") }
  end

  describe "PWA" do
    it { expect(get: "/manifest").to route_to("pwa#manifest") }
    it { expect(get: "/service-worker").to route_to("pwa#service_worker") }
  end

  describe "offline" do
    it { expect(get: "/offline").to route_to("pages#offline") }
  end

  describe "billboard click" do
    it { expect(get: "/click/1").to route_to("billboard_clicks#show", id: "1") }
  end

  describe "public articles" do
    it { expect(get: "/articles").to route_to("articles#index") }
    it { expect(get: "/articles/1").to route_to("articles#show", id: "1") }
    it { expect(get: "/").to route_to("articles#index") }
    it { expect(get: "/region/mumbai").to route_to("articles#index", slug: "mumbai") }
    it { expect(get: "/category/sports").to route_to("articles#index", slug: "sports") }
  end

  describe "comments" do
    it { expect(post: "/articles/1/comments").to route_to("comments#create", article_id: "1") }
    it { expect(delete: "/articles/1/comments/2").to route_to("comments#destroy", article_id: "1", id: "2") }
  end

  describe "likes" do
    it { expect(post: "/articles/1/like/toggle").to route_to("likes#toggle", article_id: "1") }
  end

  describe "admin" do
    it { expect(get: "/admin").to route_to("admin/dashboard#show") }
    it { expect(get: "/admin/articles").to route_to("admin/articles#index") }
    it { expect(post: "/admin/articles").to route_to("admin/articles#create") }
    it { expect(get: "/admin/articles/1").to route_to("admin/articles#show", id: "1") }
    it { expect(get: "/admin/articles/1/edit").to route_to("admin/articles#edit", id: "1") }
    it { expect(patch: "/admin/articles/1").to route_to("admin/articles#update", id: "1") }
    it { expect(delete: "/admin/articles/1").to route_to("admin/articles#destroy", id: "1") }
    it { expect(patch: "/admin/articles/1/publish").to route_to("admin/articles#publish", id: "1") }
    it { expect(patch: "/admin/articles/1/approve").to route_to("admin/articles#approve", id: "1") }
    it { expect(patch: "/admin/articles/1/reject").to route_to("admin/articles#reject", id: "1") }
    it { expect(patch: "/admin/articles/1/submit_for_review").to route_to("admin/articles#submit_for_review", id: "1") }

    it { expect(get: "/admin/users").to route_to("admin/users#index") }
    it { expect(post: "/admin/users").to route_to("admin/users#create") }
    it { expect(get: "/admin/users/1/edit").to route_to("admin/users#edit", id: "1") }
    it { expect(patch: "/admin/users/1").to route_to("admin/users#update", id: "1") }
    it { expect(delete: "/admin/users/1").to route_to("admin/users#destroy", id: "1") }
    it { expect(patch: "/admin/users/1/toggle_status").to route_to("admin/users#toggle_status", id: "1") }

    it { expect(get: "/admin/regions").to route_to("admin/regions#index") }
    it { expect(post: "/admin/regions").to route_to("admin/regions#create") }
    it { expect(get: "/admin/regions/1/edit").to route_to("admin/regions#edit", id: "1") }
    it { expect(patch: "/admin/regions/1").to route_to("admin/regions#update", id: "1") }
    it { expect(delete: "/admin/regions/1").to route_to("admin/regions#destroy", id: "1") }
    it { expect(patch: "/admin/regions/1/toggle_active").to route_to("admin/regions#toggle_active", id: "1") }

    it { expect(get: "/admin/categories").to route_to("admin/categories#index") }
    it { expect(post: "/admin/categories").to route_to("admin/categories#create") }
    it { expect(get: "/admin/categories/1/edit").to route_to("admin/categories#edit", id: "1") }
    it { expect(patch: "/admin/categories/1").to route_to("admin/categories#update", id: "1") }
    it { expect(delete: "/admin/categories/1").to route_to("admin/categories#destroy", id: "1") }
    it { expect(patch: "/admin/categories/1/toggle_active").to route_to("admin/categories#toggle_active", id: "1") }

    it { expect(get: "/admin/billboards").to route_to("admin/billboards#index") }
    it { expect(post: "/admin/billboards").to route_to("admin/billboards#create") }
    it { expect(get: "/admin/billboards/1/edit").to route_to("admin/billboards#edit", id: "1") }
    it { expect(patch: "/admin/billboards/1").to route_to("admin/billboards#update", id: "1") }
    it { expect(delete: "/admin/billboards/1").to route_to("admin/billboards#destroy", id: "1") }
    it { expect(patch: "/admin/billboards/1/toggle_active").to route_to("admin/billboards#toggle_active", id: "1") }
  end

  describe "API v1 public" do
    it { expect(get: "/api/v1/articles").to route_to("api/v1/articles#index") }
    it { expect(get: "/api/v1/articles/1").to route_to("api/v1/articles#show", id: "1") }
    it { expect(get: "/api/v1/regions").to route_to("api/v1/regions#index") }
    it { expect(get: "/api/v1/regions/1").to route_to("api/v1/regions#show", id: "1") }
    it { expect(get: "/api/v1/categories").to route_to("api/v1/categories#index") }
    it { expect(get: "/api/v1/categories/1").to route_to("api/v1/categories#show", id: "1") }
  end

  describe "API v1 admin" do
    it { expect(get: "/api/v1/admin/articles").to route_to("api/v1/admin/articles#index") }
    it { expect(post: "/api/v1/admin/articles").to route_to("api/v1/admin/articles#create") }
    it { expect(get: "/api/v1/admin/articles/1").to route_to("api/v1/admin/articles#show", id: "1") }
    it { expect(patch: "/api/v1/admin/articles/1").to route_to("api/v1/admin/articles#update", id: "1") }
    it { expect(delete: "/api/v1/admin/articles/1").to route_to("api/v1/admin/articles#destroy", id: "1") }
    it { expect(patch: "/api/v1/admin/articles/1/publish").to route_to("api/v1/admin/articles#publish", id: "1") }
    it { expect(patch: "/api/v1/admin/articles/1/approve").to route_to("api/v1/admin/articles#approve", id: "1") }
    it { expect(patch: "/api/v1/admin/articles/1/reject").to route_to("api/v1/admin/articles#reject", id: "1") }
    it { expect(patch: "/api/v1/admin/articles/1/submit_for_review").to route_to("api/v1/admin/articles#submit_for_review", id: "1") }

    it { expect(get: "/api/v1/admin/users").to route_to("api/v1/admin/users#index") }
    it { expect(post: "/api/v1/admin/users").to route_to("api/v1/admin/users#create") }
    it { expect(patch: "/api/v1/admin/users/1").to route_to("api/v1/admin/users#update", id: "1") }
    it { expect(delete: "/api/v1/admin/users/1").to route_to("api/v1/admin/users#destroy", id: "1") }
    it { expect(patch: "/api/v1/admin/users/1/toggle_status").to route_to("api/v1/admin/users#toggle_status", id: "1") }

    it { expect(get: "/api/v1/admin/regions").to route_to("api/v1/admin/regions#index") }
    it { expect(post: "/api/v1/admin/regions").to route_to("api/v1/admin/regions#create") }
    it { expect(patch: "/api/v1/admin/regions/1").to route_to("api/v1/admin/regions#update", id: "1") }
    it { expect(patch: "/api/v1/admin/regions/1/toggle_active").to route_to("api/v1/admin/regions#toggle_active", id: "1") }

    it { expect(get: "/api/v1/admin/categories").to route_to("api/v1/admin/categories#index") }
    it { expect(post: "/api/v1/admin/categories").to route_to("api/v1/admin/categories#create") }
    it { expect(patch: "/api/v1/admin/categories/1").to route_to("api/v1/admin/categories#update", id: "1") }
    it { expect(patch: "/api/v1/admin/categories/1/toggle_active").to route_to("api/v1/admin/categories#toggle_active", id: "1") }
  end
end
