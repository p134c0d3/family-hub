# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check for load balancers
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA manifest
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  # Password management
  get   "change_password", to: "passwords#edit"
  patch "change_password", to: "passwords#update"

  # Forgot password (user self-service)
  resources :password_resets, only: [:new, :create]

  # Access requests (for new users)
  resources :access_requests, only: [:new, :create, :show]

  # Dashboard
  get "dashboard", to: "dashboard#show"

  # User profile
  resource :profile, only: [:show, :edit, :update] do
    patch :update_color_mode, on: :member
    patch :update_avatar, on: :member
  end

  # Settings
  resource :settings, only: [:show, :update]

  # Notifications
  resources :notifications, only: [:index] do
    patch :mark_read, on: :member
    post :mark_all_read, on: :collection
  end

  # Chats and messages
  resources :chats do
    resources :messages, only: [:create, :update, :destroy] do
      resources :reactions, only: [:create, :destroy], controller: "message_reactions"
    end
    resources :mentions, only: [:index]  # Autocomplete API for @mentions
    member do
      post :add_member
      delete :remove_member
      post :leave
    end
  end

  # Calendar and events
  get "calendar", to: "calendar#show"
  resources :events do
    resources :rsvps, only: [:create, :update, :destroy], controller: "event_rsvps"
    resources :reminders, only: [:create, :destroy], controller: "event_reminders"
  end

  # Gallery
  get "gallery", to: "gallery#index"
  resources :albums do
    resources :media_items, only: [:create, :destroy]
  end
  resources :media_items do
    resources :comments, only: [:create, :update, :destroy], controller: "media_comments"
    resources :reactions, only: [:create, :destroy], controller: "media_reactions"
  end

  # Admin namespace
  namespace :admin do
    get "/", to: "dashboard#show", as: :dashboard
    resources :access_requests, only: [:index, :show, :update, :destroy] do
      member do
        post :approve
        post :deny
      end
    end
    resources :users, only: [:index, :show, :edit, :update] do
      member do
        post :activate
        post :deactivate
        post :remove
        post :make_admin
        post :make_member
        post :reset_password
      end
    end
    resources :themes
    get "analytics", to: "analytics#index"
  end

  # Root path - redirects to login (dashboard redirects happen in controller)
  root "sessions#new"
end
