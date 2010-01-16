ActionController::Routing::Routes.draw do |map|
  map.resources :settings, :collection => {:update_all => :put}
  
  map.resources :watchers

  map.set_locale '/locale/:locale', :controller => "main", :action => "locale"
  
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  
  map.resources :searches, :member => {:broaden => :get}
  
  map.resources :user_roles
  
  map.resources :users, :member => {:restore => [:get, :put]}
  map.resource :account, :collection => {:forgot => [:get, :post], :password => :get}
  map.resources :api_keys

  map.resource :session

  map.resources :comments, :member => {:rate => :get, :destroy => :get, :report => [:get, :post]}
  map.resources :favorites, :collection => {:create => :get}, :member => {:destroy => :get}
  
  map.resources :datasets, :member => {:sitemap => :get}, :collection => {:search => :get} do |m|
    m.resources :records, :member => {:fix => :get, :update_status => :get}
  end
  
  map.resources :data_types

  map.resources :import_files, :member => {:preview => :get, :import => :post}

  map.resources :dataset_tests, :member => { :run => :get }

  dataset_description_tabs = 
            { :import_settings => :get, 
              :setup_dataset => [:get, :post], 
              :visibility => :get, 
              :set_visibility => :post,
              :datastore_status => :get,
              :add_primary_key => :get,
              :destroy => :get }
  map.resources :dataset_descriptions, :member => dataset_description_tabs, :collection => { :import => :get, :do_import => :get } do |m|
    m.resources :field_descriptions, :collection => { :order => :post, :create_for_column => :get }, :member => {:create_column => :get}
    m.resources :relationship_descriptions, :collection => { :order => :post }
  end
  map.resources :categories, :controller => "dataset_categories"
  
  map.resources :pages

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
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.connect 'api/:action.:format', :controller => 'api'
  
  map.root :controller => 'main'
end
