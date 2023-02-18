ActionController::Routing::Routes.draw do |map|
  map.resources :photo_album_comments

  map.resources :photo_album_pictures

  map.resources :photo_albums

  map.resources :news_comments

  map.resources :news_items

  map.resources :users

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.

  map.connect 'news', :controller => 'news', :action => 'index'
  map.connect 'news/page/:page_number', :controller => 'news', :action => 'page'

  map.conncet 'news/add', :controller => 'news', :action => 'add'
  map.conncet 'news/create', :controller => 'news', :action => 'create'
  map.conncet 'news/update', :controller => 'news', :action => 'update'
  map.conncet 'news/destroy', :controller => 'news', :action => 'destroy'

  map.conncet 'news/create_comment', :controller => 'news', :action => 'create_comment'
  map.conncet 'news/update_comment', :controller => 'news', :action => 'update_comment'
  map.conncet 'news/destroy_comment', :controller => 'news', :action => 'destroy_comment'

  map.conncet 'news/:id/remove', :controller => 'news', :action => 'remove'
  map.conncet 'news/:id/edit', :controller => 'news', :action => 'edit'
  map.conncet 'news/:id/add_comment', :controller => 'news', :action => 'add_comment'

  map.conncet 'news/edit_comment/:id', :controller => 'news', :action => 'edit_comment'
  map.conncet 'news/remove_comment/:id', :controller => 'news', :action => 'remove_comment'

  map.connect 'news/:id', :controller => 'news', :action => 'view'


  map.connect 'sign_in', :controller => 'home', :action => 'sign_in'
  map.connect 'sign_out', :controller => 'home', :action => 'sign_out'

	map.conncet 'photo_albums/:id/remove', :controller => 'photo_albums', :action => 'remove'
  map.connect 'photo_albums/page/:page_number', :controller => 'photo_albums', :action => 'page'

  map.connect 'photo_albums/:id/manage_pictures', :controller => 'photo_albums', :action => 'manage_pictures'

  map.root :controller => 'home'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
