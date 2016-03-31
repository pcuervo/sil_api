class CreateJoinTableNotificationsUsers < ActiveRecord::Migration
  create_join_table :notifications, :users do |t|
      t.index [:notification_id, :user_id]
      t.index [:user_id, :notification_id]
    end
end
