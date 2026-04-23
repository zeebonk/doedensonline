DoedensOnline::Application.routes.draw do
  resources :photo_album_comments do
    get 'remove', on: :member
  end
  resources :photo_album_pictures
  resources :photo_albums
  resources :news_comments
  resources :news_items
  resources :users

  get  'sign_in',  to: 'home#sign_in'
  get  'sign_out', to: 'home#sign_out'

  post 'home/authenticate',        to: 'home#authenticate'
  post 'home/destroy_session',     to: 'home#destroy_session'
  get  'home/password_forgotten',  to: 'home#password_forgotten'
  post 'home/reset_password',      to: 'home#reset_password'

  get  'news',                          to: 'news#index'
  get  'news/page/:page_number',        to: 'news#page'

  get  'news/add',                      to: 'news#add'
  post 'news/create',                   to: 'news#create'
  post 'news/update',                   to: 'news#update'
  post 'news/destroy',                  to: 'news#destroy'

  post 'news/create_comment',           to: 'news#create_comment'
  post 'news/update_comment',           to: 'news#update_comment'
  post 'news/destroy_comment',          to: 'news#destroy_comment'

  get  'news/:id/remove',               to: 'news#remove'
  get  'news/:id/edit',                 to: 'news#edit'
  get  'news/:id/add_comment',          to: 'news#add_comment'

  get  'news/edit_comment/:id',         to: 'news#edit_comment'
  get  'news/remove_comment/:id',       to: 'news#remove_comment'

  get  'news/:id',                      to: 'news#view'

  get  'photo_albums/:id/remove',           to: 'photo_albums#remove'
  get  'photo_albums/page/:page_number',    to: 'photo_albums#page'
  get  'photo_albums/:id/manage_pictures',  to: 'photo_albums#manage_pictures'
  post 'photo_albums/add_picture',          to: 'photo_albums#add_picture'
  post 'photo_albums/destroy_many_pictures', to: 'photo_albums#destroy_many_pictures'

  post 'photo_album_pictures/destroy_many', to: 'photo_album_pictures#destroy_many'

  get  'settings',                      to: 'settings#index'
  get  'settings/profile',              to: 'settings#profile'
  get  'settings/password',             to: 'settings#password'
  get  'settings/notifications',        to: 'settings#notifications'
  post 'settings/update_profile',       to: 'settings#update_profile'
  post 'settings/update_password',      to: 'settings#update_password'
  post 'settings/update_notifications', to: 'settings#update_notifications'

  root to: 'home#index'
end
