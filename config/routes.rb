Datacamp::Application.routes.draw do |map|
  map.namespace :settings do |ns|
    ns.resources :pages
  end
  
  map.resources :settings, :collection => {:update_all => :put}
  
  map.resources :watchers

  map.set_locale '/locale/:locale', :controller => "main", :action => "locale"
  
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'
  
  map.resources :searches, :member => {:broaden => :get}, :collection => {:quick => :post}
  
  map.resources :user_roles
  
  map.resources :users, :member => {:restore => [:get, :put]}
  map.resource :account, :collection => {:forgot => [:get, :post], :password => :get}
  map.resources :api_keys

  map.resource :session

  map.resources :comments, :member => {:rate => :get, :destroy => :get, :report => [:get, :post]}
  map.resources :favorites, :collection => {:create => :get}, :member => {:destroy => :get}
  
  map.resources :datasets, :member => {:sitemap => :get, :batch_edit => :put}, :collection => {:search => :get} do |m|
    m.resources :records, :member => {:fix => :get, :update_status => :get}
  end
  
  map.resources :data_types

  map.resources :import_files, :member => {:preview => :get, :import => :post, :status => :get}

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
    m.resources :field_descriptions, :collection => { :order => :post, :create_for_column => :get }, :member => {:create_column => :get }
  end
  map.resources :categories, :controller => "dataset_categories"
  
  map.resources :pages

  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

  map.connect 'api/:action.:format', :controller => 'api'
  
  map.root :controller => 'main'
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end