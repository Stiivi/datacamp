# -*- encoding : utf-8 -*-
Datacamp::Application.routes.draw do

  resources :parsers, only: [:index, :show] do
    member do
      post :run
      get :download
    end
  end

  match '/locale/:locale' =>  'main#locale', :as => 'set_locale'

  match '/logout' => 'sessions#destroy', :as => :logout
  match '/login' => 'sessions#new', :as => :login
  match '/register' => 'sessions#create'
  match '/signup' => 'sessions#new'


  scope "(:locale)", :locale => /sk|en/ do

    # Settings backend
    namespace :settings do
      resources :pages
      resources :blocks do
        post :update_positions, on: :collection
      end
      resources :users do
        member do
          get :restore
          put :restore
        end
      end
      resources :comments, only: [:index, :edit, :update, :destroy]
      resources :system_variables, only: :index do
        put :update_all, on: :collection
      end
      resources :news, only: [:index, :new, :create, :edit, :update]
    end
    ##################


    # Settings frontend
    resources :pages, except: [:index] do
      resources :blocks
    end

    resources :comments, only: [:new, :create] do
      member do
        get :rate, :report
        post :report
      end
    end

    resources :news, only: [:index, :show]
    ##################


    resources :searches, only: [:new, :create, :show] do
      collection do
        post :quick
        get :predicate_rows
      end
    end




    resources :watchers
    resources :activities, only: [:index, :show]

    resources :data_repairs do
      collection do
        get :update_columns, :update_columns_names
        post :start_repair, :sphinx_reindex
      end
    end

    resources :import_files do
      member do
        get :preview, :state, :cancel
        post :import, :delete_records
      end
    end

    resource :account do
      collection do
        get :forgot, :password
        post :forgot
      end
    end

    resources :api_keys

    resource :session

    resources :favorites do
      get :create, :on => :collection
    end

    resources :datasets do
      get :search, :on => :collection
      resources :records do
        get :fix, :update_status, :on => :member
        member do
          post :add_relationship
          delete :delete_relationship
        end
      end
      member do
        get :sitemap
        put :batch_edit
        match ':everyone' => 'datasets#show'
      end
    end

    resources :dataset_descriptions do
      member do
        get :import_settings,
            :setup_dataset,
            :visibility,
            :edit_field_description_categories
        post :setup_dataset
        put :update_field_description_categories
      end
      collection do
        post :update_positions
      end
      resources :field_descriptions do
        collection do
          post :order
        end
      end

      resources :relations
      resource :datastore_states, only: [:show] do
        post :create_column_description
        post :create_table_column
      end
    end
    resources :dataset_initializations, only: [:index, :create]
    resources :categories, :controller => "dataset_categories"
    resources :dataset_categories
    resources :field_description_categories
  end


  match '/api/:action.:format', :controller => 'api'
  
  root :to => 'main#index'
  
  match ':controller(/:action(/:id(.:format)))'
  match '*path' => redirect('/')
  
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
