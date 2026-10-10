DoedensOnline::Application.routes.draw do
  resources :photo_albums do
    member do
      get :remove
    end
    resources :comments, controller: 'photo_album_comments', only: %i[new create edit update destroy] do
      get :remove, on: :member
    end
    resources :pictures, controller: 'photo_album_pictures', only: %i[index create] do
      post :destroy_many, on: :collection
    end
  end
  resources :users

  get  'sign_in',  to: 'home#sign_in'
  get  'sign_out', to: 'home#sign_out'

  post 'home/authenticate',        to: 'home#authenticate'
  post 'home/destroy_session',     to: 'home#destroy_session'
  get  'home/password_forgotten',  to: 'home#password_forgotten'
  post 'home/reset_password',      to: 'home#reset_password'

  resources :news_items, path: 'news' do
    member do
      get :remove
    end
    resources :news_comments, path: 'comments', only: %i[new create edit update destroy] do
      get :remove, on: :member
    end
  end

  post 'csp_reports', to: 'csp_reports#create'

  get 'up', to: 'rails/health#show', as: :rails_health_check

  get  'settings',                      to: 'settings#index'
  get  'settings/profile',              to: 'settings#profile'
  get  'settings/password',             to: 'settings#password'
  get  'settings/notifications',        to: 'settings#notifications'
  patch 'settings/update_profile',      to: 'settings#update_profile'
  patch 'settings/update_password',     to: 'settings#update_password'
  patch 'settings/update_notifications', to: 'settings#update_notifications'

  root to: 'home#index'
end
