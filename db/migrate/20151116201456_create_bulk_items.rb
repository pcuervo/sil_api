class CreateBulkItems < ActiveRecord::Migration
  def change
    create_table :bulk_items do |t|
      t.string :quantity, default: 0
      
      t.timestamps null: false
    end
  end
end
