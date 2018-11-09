class AddFolioToDelivery < ActiveRecord::Migration[5.0]
  def change
    add_column :deliveries, :folio, :string, default: '-'
  end
end
