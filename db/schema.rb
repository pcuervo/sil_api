# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160920230149) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bulk_items", force: :cascade do |t|
    t.integer  "quantity",   default: 0
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "bundle_item_parts", force: :cascade do |t|
    t.string   "name"
    t.string   "serial_number",  default: "-"
    t.string   "brand",          default: "-"
    t.string   "model",          default: "-"
    t.integer  "bundle_item_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "status",         default: 1
  end

  add_index "bundle_item_parts", ["bundle_item_id"], name: "index_bundle_item_parts_on_bundle_item_id", using: :btree

  create_table "bundle_items", force: :cascade do |t|
    t.integer  "num_parts",   default: 0
    t.boolean  "is_complete", default: true
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "check_in_transactions", force: :cascade do |t|
    t.date     "entry_date"
    t.date     "estimated_issue_date"
    t.string   "delivery_company"
    t.string   "delivery_company_contact"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "check_out_transactions", force: :cascade do |t|
    t.date     "exit_date"
    t.date     "estimated_return_date"
    t.string   "pickup_company"
    t.string   "pickup_company_contact"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "client_contacts", force: :cascade do |t|
    t.string   "phone",         default: "-"
    t.string   "phone_ext",     default: "-"
    t.string   "business_unit", default: "-"
    t.integer  "client_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.float    "discount",      default: 1.0
  end

  add_index "client_contacts", ["client_id"], name: "index_client_contacts_on_client_id", using: :btree

  create_table "clients", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "deliveries", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "delivery_user_id",                null: false
    t.string   "company"
    t.string   "addressee"
    t.string   "addressee_phone"
    t.text     "address"
    t.string   "latitude"
    t.string   "longitude"
    t.integer  "status",              default: 1
    t.text     "additional_comments"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.datetime "date_time"
    t.integer  "supplier_id"
  end

  add_index "deliveries", ["user_id"], name: "index_deliveries_on_user_id", using: :btree

  create_table "delivery_items", force: :cascade do |t|
    t.integer  "inventory_item_id"
    t.integer  "delivery_id"
    t.integer  "quantity",          default: 1
    t.integer  "part_id",           default: 0
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "delivery_items", ["delivery_id"], name: "index_delivery_items_on_delivery_id", using: :btree
  add_index "delivery_items", ["inventory_item_id"], name: "index_delivery_items_on_inventory_item_id", using: :btree

  create_table "delivery_request_items", force: :cascade do |t|
    t.integer  "inventory_item_id"
    t.integer  "delivery_request_id"
    t.integer  "quantity",            default: 1
    t.integer  "part_id",             default: 0
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "delivery_request_items", ["delivery_request_id"], name: "index_delivery_request_items_on_delivery_request_id", using: :btree
  add_index "delivery_request_items", ["inventory_item_id"], name: "index_delivery_request_items_on_inventory_item_id", using: :btree

  create_table "delivery_requests", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "company"
    t.string   "addressee"
    t.string   "addressee_phone"
    t.text     "address"
    t.string   "latitude"
    t.string   "longitude"
    t.text     "additional_comments"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.datetime "date_time"
  end

  add_index "delivery_requests", ["user_id"], name: "index_delivery_requests_on_user_id", using: :btree

  create_table "inventory_item_requests", force: :cascade do |t|
    t.string   "name",                     default: " "
    t.text     "description"
    t.integer  "quantity"
    t.string   "item_type"
    t.integer  "project_id"
    t.integer  "pm_id"
    t.integer  "ae_id"
    t.integer  "state"
    t.date     "validity_expiration_date"
    t.date     "entry_date"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  create_table "inventory_items", force: :cascade do |t|
    t.string   "name",                                              default: " "
    t.text     "description"
    t.string   "image_url",                                         default: "default_item.png"
    t.integer  "status",                                            default: 1
    t.string   "item_type"
    t.string   "barcode"
    t.integer  "user_id"
    t.integer  "project_id"
    t.integer  "client_id"
    t.integer  "actable_id"
    t.string   "actable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "item_img_file_name"
    t.string   "item_img_content_type"
    t.integer  "item_img_file_size"
    t.datetime "item_img_updated_at"
    t.date     "validity_expiration_date"
    t.integer  "state",                                             default: 1
    t.decimal  "value",                    precision: 10, scale: 2, default: 0.0
    t.string   "storage_type"
    t.integer  "is_high_value",                                     default: 0
  end

  add_index "inventory_items", ["client_id"], name: "index_inventory_items_on_client_id", using: :btree
  add_index "inventory_items", ["project_id"], name: "index_inventory_items_on_project_id", using: :btree
  add_index "inventory_items", ["user_id"], name: "index_inventory_items_on_user_id", using: :btree

  create_table "inventory_transactions", force: :cascade do |t|
    t.integer  "inventory_item_id"
    t.string   "concept"
    t.text     "additional_comments"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "actable_id"
    t.string   "actable_type"
    t.integer  "quantity"
  end

  add_index "inventory_transactions", ["inventory_item_id"], name: "index_inventory_transactions_on_inventory_item_id", using: :btree

  create_table "item_locations", force: :cascade do |t|
    t.integer  "inventory_item_id"
    t.integer  "warehouse_location_id"
    t.integer  "units",                 default: 1
    t.integer  "quantity",              default: 1
    t.integer  "part_id",               default: 0
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "item_locations", ["inventory_item_id"], name: "index_item_locations_on_inventory_item_id", using: :btree
  add_index "item_locations", ["warehouse_location_id"], name: "index_item_locations_on_warehouse_location_id", using: :btree

  create_table "logs", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "sys_module"
    t.string   "action"
    t.integer  "actor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "logs", ["user_id"], name: "index_logs_on_user_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.string   "message"
    t.integer  "inventory_item_id"
    t.integer  "status",            default: 1
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "title",                         null: false
  end

  create_table "notifications_users", id: false, force: :cascade do |t|
    t.integer "notification_id", null: false
    t.integer "user_id",         null: false
  end

  add_index "notifications_users", ["notification_id", "user_id"], name: "index_notifications_users_on_notification_id_and_user_id", using: :btree
  add_index "notifications_users", ["user_id", "notification_id"], name: "index_notifications_users_on_user_id_and_notification_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.string   "litobel_id", default: "-"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "client_id"
  end

  add_index "projects", ["client_id"], name: "index_projects_on_client_id", using: :btree

  create_table "projects_users", id: false, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "user_id",    null: false
  end

  add_index "projects_users", ["project_id", "user_id"], name: "index_projects_users_on_project_id_and_user_id", using: :btree
  add_index "projects_users", ["user_id", "project_id"], name: "index_projects_users_on_user_id_and_project_id", using: :btree

  create_table "suppliers", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "system_settings", force: :cascade do |t|
    t.integer  "units_per_location",                         default: 50
    t.decimal  "cost_per_location",  precision: 8, scale: 2, default: 0.0
    t.decimal  "cost_high_value",    precision: 8, scale: 2, default: 0.0
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
  end

  create_table "unit_items", force: :cascade do |t|
    t.string   "serial_number", default: " "
    t.string   "brand",         default: " "
    t.string   "model",         default: " "
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "auth_token",             default: ""
    t.integer  "role",                   default: 2,  null: false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "actable_id"
    t.string   "actable_type"
  end

  add_index "users", ["auth_token"], name: "index_users_on_auth_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "warehouse_locations", force: :cascade do |t|
    t.string   "name",              default: ""
    t.integer  "units",             default: 1
    t.integer  "status",            default: 1
    t.integer  "warehouse_rack_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "warehouse_locations", ["warehouse_rack_id"], name: "index_warehouse_locations_on_warehouse_rack_id", using: :btree

  create_table "warehouse_racks", force: :cascade do |t|
    t.string   "name",       default: ""
    t.integer  "row",        default: 1
    t.integer  "column",     default: 1
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "warehouse_transactions", force: :cascade do |t|
    t.integer  "inventory_item_id"
    t.integer  "warehouse_location_id"
    t.integer  "concept",               default: 1
    t.integer  "units",                 default: 1
    t.integer  "quantity",              default: 1
    t.integer  "part_id",               default: 0
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "warehouse_transactions", ["inventory_item_id"], name: "index_warehouse_transactions_on_inventory_item_id", using: :btree
  add_index "warehouse_transactions", ["warehouse_location_id"], name: "index_warehouse_transactions_on_warehouse_location_id", using: :btree

  create_table "withdraw_request_items", force: :cascade do |t|
    t.integer  "withdraw_request_id"
    t.integer  "inventory_item_id"
    t.integer  "quantity",            default: 1
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  add_index "withdraw_request_items", ["inventory_item_id"], name: "index_withdraw_request_items_on_inventory_item_id", using: :btree
  add_index "withdraw_request_items", ["withdraw_request_id"], name: "index_withdraw_request_items_on_withdraw_request_id", using: :btree

  create_table "withdraw_requests", force: :cascade do |t|
    t.integer  "user_id"
    t.date     "exit_date"
    t.integer  "pickup_company_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "withdraw_requests", ["user_id"], name: "index_withdraw_requests_on_user_id", using: :btree

  add_foreign_key "bundle_item_parts", "bundle_items"
  add_foreign_key "client_contacts", "clients"
  add_foreign_key "deliveries", "users"
  add_foreign_key "delivery_request_items", "delivery_requests"
  add_foreign_key "delivery_request_items", "inventory_items"
  add_foreign_key "delivery_requests", "users"
  add_foreign_key "inventory_items", "clients"
  add_foreign_key "inventory_items", "projects"
  add_foreign_key "inventory_items", "users"
  add_foreign_key "inventory_transactions", "inventory_items"
  add_foreign_key "item_locations", "inventory_items"
  add_foreign_key "item_locations", "inventory_items"
  add_foreign_key "item_locations", "warehouse_locations"
  add_foreign_key "item_locations", "warehouse_locations"
  add_foreign_key "logs", "users"
  add_foreign_key "projects", "clients"
  add_foreign_key "warehouse_locations", "warehouse_racks"
  add_foreign_key "warehouse_transactions", "inventory_items"
  add_foreign_key "warehouse_transactions", "warehouse_locations"
  add_foreign_key "withdraw_request_items", "inventory_items"
  add_foreign_key "withdraw_request_items", "withdraw_requests"
  add_foreign_key "withdraw_requests", "users"
end
