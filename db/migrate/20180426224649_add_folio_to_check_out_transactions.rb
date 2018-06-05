class AddFolioToCheckOutTransactions < ActiveRecord::Migration
  def change
    add_column :check_out_transactions, :folio, :string, default: '-'
  end
end
