class CreateUnitItems < ActiveRecord::Migration
  def change
    create_table :unit_items do |t|
      t.string :serial_number, default: " "
      t.string :brand, default: " "
      t.string :model, default: " "

      t.timestamps null: false
    end
  end
end
