class CreateBundleItems < ActiveRecord::Migration
  def change
    create_table :bundle_items do |t|
      t.integer :num_parts, default: 0
      t.boolean :is_complete, default: true
      t.timestamps null: false
    end
  end
end
