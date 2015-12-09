class CreateCheckInTransactions < ActiveRecord::Migration
  def change
    create_table :check_in_transactions do |t|
      t.date        :entry_date
      t.date        :estimated_issue_date
      t.string      :delivery_company
      t.string      :delivery_company_contact
      t.timestamps  null: false
    end
  end
end
