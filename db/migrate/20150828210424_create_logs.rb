class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.references  :user, index: true
      t.string      :sys_module
      t.string      :action
      t.string     :actor_id
      t.timestamps null: false
    end
    add_foreign_key :logs, :users
  end
end
