class CreateCheckOutTransactions < ActiveRecord::Migration
  def change
    create_table :check_out_transactions do |t|
      t.date        :exit_date
      t.date        :estimated_return_date
      t.string      :pickup_company
      t.string      :pickup_company_contact
      t.timestamps  null: false
    end
  end
end
