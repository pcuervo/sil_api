# frozen_string_literal: true

require 'api_constraints'

Sil::Application.routes.draw do
  devise_for :users
  # API definition
  namespace :api, defaults: { format: :json } do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: true) do
      resources :users, only: %i[index show create update destroy] do
        collection do
          post 'update/', action: 'update'
          post 'change_password/', action: 'change_password'
          post 'delete/', action: 'delete'
          get 'get_project_managers/', action: 'project_managers'
          get 'get_account_executives/', action: 'account_executives'
          get 'get_warehouse_admins/', action: 'warehouse_admins'
          get 'get_client_contacts/', action: 'client_contacts'
          get 'get_delivery_users/', action: 'delivery_users'
        end
        resources :inventory_items, only: %i[create update]
      end
      resources :sessions, only: %i[create destroy] do
        collection do
          post 'destroy/', action: 'destroy'
          post 'is_active', action: 'is_active'
        end
      end
      resources :inventory_items, only: %i[index show] do
        collection do
          get 'by_barcode/',                    action: 'by_barcode'
          get 'by_type/',                       action: 'by_type'
          get 'pending_entry/',                 action: 'pending_entry'
          get 'pending_withdrawal',             action: 'pending_withdrawal'
          get 'with_pending_location/',         action: 'with_pending_location'
          get 'reentry_with_pending_location/', action: 'reentry_with_pending_location'
          get 'is_reentry_with_pending_location/', action: 'reentry_with_pending_location?'
          get 'pending_entry_requests/',        action: 'pending_entry_requests'
          get 'pending_validation_entries/',    action: 'pending_validation_entries'
          get 'get_item_request/',              action: 'item_request'
          get 'pending_withdrawal_requests/',   action: 'pending_withdrawal_requests'
          get 'get_stats/',                     action: 'stats'
          get 'get_stats_pm_ae/',               action: 'stats_pm_ae'
          post 'authorize_entry/',              action: 'authorize_entry'
          post 'authorize_withdrawal/',         action: 'authorize_withdrawal'
          post 'multiple_withdrawal/',          action: 'multiple_withdrawal'
          post 'request_item_entry/',           action: 'request_item_entry'
          post 'cancel_item_entry_request/',    action: 'cancel_item_entry_request'
          post 'destroy/',                      action: 'destroy'
          post 'update/',                       action: 'update'
          # usados
          post 'quick_search/', action: 'quick_search'
          post 're_entry/', action: 're_entry'
          post 'replenish/', action: 'replenish'
        end
      end
      resources :unit_items, only: %i[index show] do
        collection do
          post 'withdraw/', action: 'withdraw'
          post 're_entry/', action: 're_entry'
          post 'update/',   action: 'update'
        end
      end
      resources :bulk_items, only: %i[index show update] do
        collection do
          post 'withdraw/', action: 'withdraw'
          post 're_entry/', action: 're_entry'
          post 'update/',   action: 'update'
        end
      end
      resources :bundle_items, only: %i[index show] do
        collection do
          post 'withdraw/', action: 'withdraw'
          post 're_entry/', action: 're_entry'
          post 'update/',   action: 'update'
        end
      end
      resources :projects, only: %i[index show create update] do
        collection do
          get 'get_project_users/:id',  action: 'project_users'
          get 'get_project_client/:id', action: 'project_client'
          get 'by_user/:id',            action: 'by_user'
          get 'lean_index',             action: 'lean_index'
          post 'add_users',             action: 'add_users'
          post 'remove_user',           action: 'remove_user'
          post 'update',                action: 'update'
          post 'destroy',               action: 'destroy'
          post 'transfer_inventory',    action: 'transfer_inventory'
          post 'transfer_inventory_items', action: 'transfer_inventory_items'
          post 'inventory', action: 'inventory'
        end
      end
      resources :clients, only: %i[show index create destroy] do
        collection do
          post 'update', action: 'update'
        end
      end
      resources :client_contacts, only: %i[show index create update destroy] do
        collection do
          get 'get_by_client/', action: 'by_client'
          get 'by_user/:id', action: 'by_user'
          post 'inventory_items',  action: 'inventory_items'
          get 'stats/:id',         action: 'stats'
          post 'update',           action: 'update'
          post 'destroy',          action: 'destroy'
        end
      end
      resources :inventory_transactions, only: %i[show index] do
        collection do
          get 'get_check_ins', action: 'check_ins'
          get 'get_check_outs', action: 'check_outs'
          get 'get_check_outs_by_client/:id', action: 'check_outs_by_client'
          post 'search', action: 'search'
          get 'last_checkout_folio', action: 'last_checkout_folio'
          get 'last_checkin_folio', action: 'last_checkin_folio'
          post 'by_folio', action: 'by_folio'
          post 'latest', action: 'latest'
          post 'latest_by_user', action: 'latest_by_user'
        end
      end
      resources :warehouse_locations, only: %i[show index] do
        collection do
          post 'locate_item',       action: 'locate_item'
          post 'locate_bulk',       action: 'locate_bulk'
          post 'relocate_item',     action: 'relocate_item'
          post 'update',            action: 'update'
          post 'mark_as_full',      action: 'mark_as_full'
          post 'mark_as_available', action: 'mark_as_available'
          post 'csv_locate',        action: 'csv_locate'
          post 'remove_item'
        end
      end
      resources :warehouse_racks, only: %i[show index create] do
        collection do
          get 'get_available_locations/:id', action: 'available_locations'
          get 'show_details/:id', action: 'show_details'
          get 'get_items/:id',    action: 'items'
          post 'destroy',         action: 'destroy'
          post 'empty', action: 'empty'
          get 'stats', action: 'stats'
        end
      end
      resources :item_locations, only: %i[show index create] do
        collection do
          post 'get_item_location_details/', action: 'details'
        end
      end
      resources :suppliers, only: %i[show index create update destroy] do
        collection do
          post 'update/', action: 'update'
        end
      end
      resources :warehouse_transactions, only: [:index]
      resources :notifications, only: %i[index show] do
        collection do
          get 'get_num_unread',   action: 'num_unread'
          get 'get_unread',       action: 'unread'
          get 'get_read',         action: 'read'
          post 'destroy',         action: 'destroy'
          post 'mark_as_read',    action: 'mark_as_read'
        end
      end
      resources :deliveries, only: %i[show index create update] do
        collection do
          get 'stats',                action: 'stats'
          get 'pending_approval',     action: 'pending_approval'
          post 'update',              action: 'update'
          post 'by_delivery_man/',    action: 'by_delivery_man'
          post 'by_keyword/', action: 'by_keyword'
        end
      end
      resources :system_settings, only: [:show] do
        collection do
          post 'update', action: 'update'
        end
      end
      resources :withdraw_requests, only: %i[index create show] do
        collection do
          post 'authorize_withdrawal',  action: 'authorize_withdrawal'
          post 'cancel_withdrawal',     action: 'cancel_withdrawal'
          get 'by_user/:id',            action: 'by_user'
        end
      end
      resources :delivery_requests, only: %i[show index create] do
        collection do
          post 'authorize_delivery/', action: 'authorize_delivery'
          post 'reject_delivery/',    action: 'reject_delivery'
          post 'cancel_delivery/',    action: 'cancel_delivery'
          get 'by_user/:id',          action: 'by_user'
        end
      end
      resources :item_types, only: %i[create index show] do
        collection do
          post 'update/', action: 'update'
          post 'destroy', action: 'destroy'
        end
      end
      resources :logs, only: %i[index]
    end
  end

  match '*path', via: [:options], to: ->(_) { [204, { 'Content-Type' => 'text/plain' }] }
end
