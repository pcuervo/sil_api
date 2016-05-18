class CreateWithdrawRequests < ActiveRecord::Migration
  def change
    create_table :withdraw_requests do |t|  
      t.references  :user,         index: true
      t.date        :exit_date
      t.integer     :pickup_company_id       
      t.timestamps null: false
    end
    add_foreign_key :withdraw_requests, :users
  end
end
