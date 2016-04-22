class AddDiscountToClientContacts < ActiveRecord::Migration
  def change
    add_column :client_contacts, :discount, :float, :precision => 4, :scale => 2, :default => 1.0
  end
end
