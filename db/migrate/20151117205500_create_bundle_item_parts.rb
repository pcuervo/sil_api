class CreateBundleItemParts < ActiveRecord::Migration
  def change
    create_table :bundle_item_parts do |t|
      t.string      :name
      t.string      :serial_number,       default: "-"
      t.string      :brand,               default: "-"
      t.string      :model,               default: "-"
      t.references  :bundle_item,         index: true
      t.timestamps  null: false
    end
    add_foreign_key :bundle_item_parts,   :bundle_items
  end
end
