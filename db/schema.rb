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

ActiveRecord::Schema.define(version: 20160121025920) do

  create_table "audits", force: :cascade do |t|
    t.integer  "auditable_id",    limit: 4
    t.string   "auditable_type",  limit: 255
    t.integer  "associated_id",   limit: 4
    t.string   "associated_type", limit: 255
    t.integer  "user_id",         limit: 4
    t.string   "user_type",       limit: 255
    t.string   "username",        limit: 255
    t.string   "action",          limit: 255
    t.text     "audited_changes", limit: 65535
    t.integer  "version",         limit: 4,     default: 0
    t.string   "comment",         limit: 255
    t.string   "remote_address",  limit: 255
    t.string   "request_uuid",    limit: 255
    t.datetime "created_at"
  end

  add_index "audits", ["associated_id", "associated_type"], name: "associated_index", using: :btree
  add_index "audits", ["auditable_id", "auditable_type"], name: "auditable_index", using: :btree
  add_index "audits", ["created_at"], name: "index_audits_on_created_at", using: :btree
  add_index "audits", ["request_uuid"], name: "index_audits_on_request_uuid", using: :btree
  add_index "audits", ["user_id", "user_type"], name: "user_index", using: :btree

  create_table "bulk_items", force: :cascade do |t|
    t.string   "quantity",   limit: 255, default: "0"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  create_table "bundle_item_parts", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "serial_number",  limit: 255, default: "-"
    t.string   "brand",          limit: 255, default: "-"
    t.string   "model",          limit: 255, default: "-"
    t.integer  "bundle_item_id", limit: 4
    t.integer  "status",         limit: 4,   default: 1
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "bundle_item_parts", ["bundle_item_id"], name: "index_bundle_item_parts_on_bundle_item_id", using: :btree

  create_table "bundle_items", force: :cascade do |t|
    t.integer  "num_parts",   limit: 4, default: 0
    t.boolean  "is_complete", limit: 1, default: true
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  create_table "check_in_transactions", force: :cascade do |t|
    t.date     "entry_date"
    t.date     "estimated_issue_date"
    t.string   "delivery_company",         limit: 255
    t.string   "delivery_company_contact", limit: 255
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  create_table "check_out_transactions", force: :cascade do |t|
    t.date     "exit_date"
    t.date     "estimated_return_date"
    t.string   "pickup_company",         limit: 255
    t.string   "pickup_company_contact", limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  create_table "client_contacts", force: :cascade do |t|
    t.string   "phone",         limit: 255
    t.string   "phone_ext",     limit: 255, default: "-"
    t.string   "business_unit", limit: 255, default: "-"
    t.integer  "client_id",     limit: 4
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "client_contacts", ["client_id"], name: "index_client_contacts_on_client_id", using: :btree

  create_table "clients", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "inventory_items", force: :cascade do |t|
    t.string   "name",                     limit: 255,                            default: " "
    t.text     "description",              limit: 65535
    t.string   "image_url",                limit: 255,                            default: "default_item.png"
    t.integer  "status",                   limit: 4,                              default: 1
    t.integer  "user_id",                  limit: 4
    t.integer  "project_id",               limit: 4
    t.decimal  "value",                                  precision: 10, scale: 2, default: 0.0
    t.integer  "actable_id",               limit: 4
    t.string   "actable_type",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "item_img_file_name",       limit: 255
    t.string   "item_img_content_type",    limit: 255
    t.integer  "item_img_file_size",       limit: 4
    t.datetime "item_img_updated_at"
    t.string   "item_type",                limit: 255
    t.string   "barcode",                  limit: 255
    t.date     "validity_expiration_date"
    t.integer  "state",                    limit: 4,                              default: 1
  end

  add_index "inventory_items", ["project_id"], name: "index_inventory_items_on_project_id", using: :btree
  add_index "inventory_items", ["user_id"], name: "index_inventory_items_on_user_id", using: :btree

  create_table "inventory_transactions", force: :cascade do |t|
    t.integer  "inventory_item_id",   limit: 4
    t.string   "concept",             limit: 255
    t.string   "storage_type",        limit: 255,   default: "temporal"
    t.text     "additional_comments", limit: 65535
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "actable_id",          limit: 4
    t.string   "actable_type",        limit: 255
    t.integer  "quantity",            limit: 4
  end

  add_index "inventory_transactions", ["inventory_item_id"], name: "index_inventory_transactions_on_inventory_item_id", using: :btree

  create_table "item_locations", force: :cascade do |t|
    t.integer  "inventory_item_id",     limit: 4
    t.integer  "warehouse_location_id", limit: 4
    t.integer  "units",                 limit: 4, default: 1
    t.integer  "quantity",              limit: 4, default: 1
    t.integer  "part_id",               limit: 4, default: 0
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "item_locations", ["inventory_item_id"], name: "index_item_locations_on_inventory_item_id", using: :btree
  add_index "item_locations", ["warehouse_location_id"], name: "index_item_locations_on_warehouse_location_id", using: :btree

  create_table "logs", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "sys_module", limit: 255
    t.string   "action",     limit: 255
    t.integer  "actor_id",   limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "logs", ["user_id"], name: "index_logs_on_user_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string   "name",       limit: 255, default: "empty"
    t.string   "litobel_id", limit: 255, default: "-"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "client_id",  limit: 4
  end

  add_index "projects", ["client_id"], name: "index_projects_on_client_id", using: :btree

  create_table "projects_users", id: false, force: :cascade do |t|
    t.integer "project_id", limit: 4, null: false
    t.integer "user_id",    limit: 4, null: false
  end

  add_index "projects_users", ["project_id", "user_id"], name: "index_projects_users_on_project_id_and_user_id", using: :btree
  add_index "projects_users", ["user_id", "project_id"], name: "index_projects_users_on_user_id_and_project_id", using: :btree

  create_table "suppliers", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "unit_items", force: :cascade do |t|
    t.string   "serial_number", limit: 255, default: " "
    t.string   "brand",         limit: 255, default: " "
    t.string   "model",         limit: 255, default: " "
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "auth_token",             limit: 255, default: ""
    t.integer  "role",                   limit: 4,   default: 2,  null: false
    t.string   "first_name",             limit: 255
    t.string   "last_name",              limit: 255
    t.string   "avatar_file_name",       limit: 255
    t.string   "avatar_content_type",    limit: 255
    t.integer  "avatar_file_size",       limit: 4
    t.datetime "avatar_updated_at"
    t.integer  "actable_id",             limit: 4
    t.string   "actable_type",           limit: 255
  end

  add_index "users", ["auth_token"], name: "index_users_on_auth_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "warehouse_locations", force: :cascade do |t|
    t.string   "name",              limit: 255, default: ""
    t.integer  "units",             limit: 4,   default: 1
    t.integer  "status",            limit: 4,   default: 1
    t.integer  "warehouse_rack_id", limit: 4
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "warehouse_locations", ["warehouse_rack_id"], name: "index_warehouse_locations_on_warehouse_rack_id", using: :btree

  create_table "warehouse_racks", force: :cascade do |t|
    t.string   "name",       limit: 255, default: ""
    t.integer  "row",        limit: 4,   default: 1
    t.integer  "column",     limit: 4,   default: 1
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "warehouse_transactions", force: :cascade do |t|
    t.integer  "inventory_item_id",     limit: 4
    t.integer  "warehouse_location_id", limit: 4
    t.integer  "concept",               limit: 4, default: 1
    t.integer  "units",                 limit: 4, default: 1
    t.integer  "quantity",              limit: 4, default: 1
    t.integer  "part_id",               limit: 4, default: 0
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "warehouse_transactions", ["inventory_item_id"], name: "index_warehouse_transactions_on_inventory_item_id", using: :btree
  add_index "warehouse_transactions", ["warehouse_location_id"], name: "index_warehouse_transactions_on_warehouse_location_id", using: :btree

  add_foreign_key "bundle_item_parts", "bundle_items"
  add_foreign_key "client_contacts", "clients"
  add_foreign_key "inventory_items", "projects"
  add_foreign_key "inventory_items", "users"
  add_foreign_key "inventory_transactions", "inventory_items"
  add_foreign_key "item_locations", "inventory_items"
  add_foreign_key "item_locations", "warehouse_locations"
  add_foreign_key "logs", "users"
  add_foreign_key "projects", "clients"
  add_foreign_key "warehouse_locations", "warehouse_racks"
  add_foreign_key "warehouse_transactions", "inventory_items"
  add_foreign_key "warehouse_transactions", "warehouse_locations"
end
