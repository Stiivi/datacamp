ActionController::Routing::Routes.draw do |map|
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
end
