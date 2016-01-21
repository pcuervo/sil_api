require 'api_constraints'

Sil::Application.routes.draw do
  devise_for :users
  # API definition
  namespace :api, defaults: {format: :json} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1 , default: true) do
      
      resources :users, :only => [:index, :show, :create, :update, :destroy] do
        collection do 
          post 'update/', :action => 'update'
        end
        resources :inventory_items, :only => [:create]
        resources :unit_items, :only => [:create]
          collection do 
            get 'get_project_managers/', :action => 'get_project_managers'
            get 'get_account_executives/', :action => 'get_account_executives'
          end
        resources :bulk_items, :only => [:create]
        resources :bundle_items, :only => [:create]
      end
      resources :sessions, :only => [:create, :destroy] do
        collection do
          post 'destroy/', :action => 'destroy'
        end
      end
      resources :inventory_items, :only => [:index, :show] do
        collection do
          get 'by_barcode/', :action => 'by_barcode'
          get 'by_type/', :action => 'by_type'
        end
      end
      resources :unit_items, :only => [:index, :show] do 
        collection do
          post 'withdraw/', :action => 'withdraw'
          post 're_entry/', :action => 're_entry'
        end
      end
      resources :bulk_items, :only => [:index, :show] do
        collection do
          post 'withdraw/', :action => 'withdraw'
          post 're_entry/', :action => 're_entry'
        end
      end
      resources :bundle_items, :only => [:index, :show] do
        collection do
          post 'withdraw/', :action => 'withdraw'
        end
      end
      resources :projects, :only => [:index, :show, :create, :update, :destroy] do
        collection do 
          get 'get_project_users/:id',  :action => 'get_project_users'
          get 'get_project_client/:id', :action => 'get_project_client'
          get 'by_user/:id',            :action => 'by_user'
        end
      end
      resources :clients, :only => [:show, :index, :create, :update, :destroy]
      resources :client_contacts, :only => [:show, :index, :create, :update, :destroy] do
        collection do 
          get 'get_by_client/', :action => 'get_by_client'
          get 'inventory_items/:id', :action => 'inventory_items'
        end
      end
      resources :inventory_transactions, :only => [:show, :index] do
        collection do 
          get 'get_check_ins',  :action => 'get_check_ins'
          get 'get_check_outs', :action => 'get_check_outs'
        end
      end
      resources :warehouse_locations, :only => [:show, :index] do
        collection do
          post 'locate_item', :action => 'locate_item'
        end
      end
      resources :warehouse_racks, :only => [:show, :index] do
        collection do
          get 'get_available_locations/:id', :action => 'get_available_locations'
        end
      end
      resources :item_locations, :only => [:show, :index, :create]
      resources :suppliers, :only => [:show, :index, :create, :update, :destroy]
    end
  end


  #get '/users', to: 'api/v1/users#index'
  
end
