class InventoryTransactions < ActiveRecord::Migration
  def change
    create_table :inventory_transactions do |t|
      t.datetime    :entry_date
      t.references  :inventory_item,            index: true
      t.string      :concept                    
      t.string      :storage_type,              default: "temporal"
      t.date        :estimated_issue_date
      t.text        :additional_comments
      t.string      :delivery_company
      t.string      :delivery_company_contact,  default: "-"
      t.timestamps  null: false
    end
    add_foreign_key :inventory_transactions, :inventory_items
  end
end
