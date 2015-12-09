class AddValidityExpirationDateToInventoryItem < ActiveRecord::Migration
  def change
    add_column :inventory_items, :validity_expiration_date, :date
  end
end
