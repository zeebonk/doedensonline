DoedensOnline::Application.routes.draw do
  resources :photo_album_comments
  resources :photo_album_pictures
  resources :photo_albums
  resources :news_comments
  resources :news_items
  resources :users

  match 'sign_in',  :to => 'home#sign_in'
  match 'sign_out', :to => 'home#sign_out'

  match 'news',                          :to => 'news#index'
  match 'news/page/:page_number',        :to => 'news#page'

  match 'news/add',                      :to => 'news#add'
  match 'news/create',                   :to => 'news#create'
  match 'news/update',                   :to => 'news#update'
  match 'news/destroy',                  :to => 'news#destroy'

  match 'news/create_comment',           :to => 'news#create_comment'
  match 'news/update_comment',           :to => 'news#update_comment'
  match 'news/destroy_comment',          :to => 'news#destroy_comment'

  match 'news/:id/remove',               :to => 'news#remove'
  match 'news/:id/edit',                 :to => 'news#edit'
  match 'news/:id/add_comment',          :to => 'news#add_comment'

  match 'news/edit_comment/:id',         :to => 'news#edit_comment'
  match 'news/remove_comment/:id',       :to => 'news#remove_comment'

  match 'news/:id',                      :to => 'news#view'

  match 'photo_albums/:id/remove',           :to => 'photo_albums#remove'
  match 'photo_albums/page/:page_number',    :to => 'photo_albums#page'
  match 'photo_albums/:id/manage_pictures',  :to => 'photo_albums#manage_pictures'

  root :to => 'home#index'

  match ':controller(/:action(/:id(.:format)))'
end
