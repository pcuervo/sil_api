class RemoveEntryRelatedFieldsFromInventoryTransaction < ActiveRecord::Migration
  def change
    remove_column :inventory_transactions, :entry_date
    remove_column :inventory_transactions, :estimated_issue_date
    remove_column :inventory_transactions, :delivery_company
    remove_column :inventory_transactions, :delivery_company_contact
  end
end
