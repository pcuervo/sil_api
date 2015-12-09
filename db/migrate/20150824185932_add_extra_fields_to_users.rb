class AddExtraFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth_token, :string, default: ""
    add_column :users, :role, :integer, :null => false, :default => 2
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_index :users, :auth_token, unique: true
  end
end