class AddActableToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t| 
      t.actable
    end
  end
end
