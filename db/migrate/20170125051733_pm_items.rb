class PmItems < ActiveRecord::Migration
  def change
    create_table :pm_items, :id => false do |t|
      t.references :user, :null => false
      t.references :inventory_item, :null => false
    end
    add_index(:pm_items, [:user_id, :inventory_item_id], :unique => true)
  end
end
