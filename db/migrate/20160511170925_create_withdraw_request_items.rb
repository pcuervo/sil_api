class CreateWithdrawRequestItems < ActiveRecord::Migration
  def change
    create_table :withdraw_request_items do |t|
      t.references  :withdraw_request,  index: true
      t.references  :inventory_item,    index: true
      t.integer     :quantity,          default: 1
      t.timestamps  null: false
    end
    add_foreign_key :withdraw_request_items, :withdraw_requests
    add_foreign_key :withdraw_request_items, :inventory_items
  end
end
