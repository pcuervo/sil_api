require 'api_constraints'

Sil::Application.routes.draw do
  devise_for :users
  # API definition
  namespace :api, defaults: {format: :json} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1 , default: true) do
      
      resources :users, :only => [:index, :show, :create, :update, :destroy] do
        collection do 
          post 'update/', :action => 'update'
          post 'change_password/', :action => 'change_password'
        end
        resources :inventory_items, :only => [:create] 
        resources :unit_items, :only => [:create]
          collection do 
            get 'get_project_managers/', :action => 'get_project_managers'
            get 'get_account_executives/', :action => 'get_account_executives'
            get 'get_client_contacts/', :action => 'get_client_contacts'
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
          get 'pending_entry/', :action => 'pending_entry'
          get 'with_pending_location/', :action => 'with_pending_location'
          get 'total_number_items/', :action => 'total_number_items'
          get 'inventory_value/', :action => 'inventory_value'
          get 'current_rent/', :action => 'current_rent'
          post 'authorize_entry/', :action => 'authorize_entry'
          post 'multiple_withdrawal/', :action => 'multiple_withdrawal'
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
          post 're_entry/', :action => 're_entry'
        end
      end
      resources :projects, :only => [:index, :show, :create, :update, :destroy] do
        collection do 
          get 'get_project_users/:id',  :action => 'get_project_users'
          get 'get_project_client/:id', :action => 'get_project_client'
          get 'by_user/:id',            :action => 'by_user'
          post 'add_users',             :action => 'add_users'
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
          post 'locate_item',   :action => 'locate_item'
          post 'locate_bundle', :action => 'locate_bundle'
          post 'locate_bulk',   :action => 'locate_bulk'
          post 'relocate_item', :action => 'relocate_item'
          post 'update',        :action => 'update'
        end
      end
      resources :warehouse_racks, :only => [:show, :index, :create] do
        collection do
          get 'get_available_locations/:id', :action => 'get_available_locations'
          get 'show_details/:id', :action => 'show_details'
          get 'get_items/:id', :action => 'get_items'
        end
      end
      resources :item_locations, :only => [:show, :index, :create] do
        collection do
          post 'get_item_location_details/', :action => 'get_details'
        end
      end
      resources :suppliers, :only => [:show, :index, :create, :update, :destroy]
      resources :warehouse_transactions, :only => [:index]
    end
  end


  #get '/users', to: 'api/v1/users#index'
  
end
