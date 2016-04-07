class CreateInventoryItemRequests < ActiveRecord::Migration
  def change
    create_table :inventory_item_requests do |t|
      t.string      :name,          default: " "
      t.text        :description
      t.integer     :quantity
      t.string      :item_type
      t.integer     :project_id 
      t.integer     :pm_id 
      t.integer     :ae_id 
      t.integer     :state
      t.date        :validity_expiration_date
      t.date        :entry_date
      t.timestamps  null: false
    end
  end
end
