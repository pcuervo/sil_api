class AddExtraPartsToInventoryItems < ActiveRecord::Migration
  def change
    add_column :inventory_items, :extra_parts, :text
  end
end
