class AddTitleToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :title, :string, :null => false, before: :message
  end
end
