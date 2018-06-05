class AddFolioToCheckInTransactions < ActiveRecord::Migration
  def change
    add_column :check_in_transactions, :folio, :string, default: '-'
  end
end
