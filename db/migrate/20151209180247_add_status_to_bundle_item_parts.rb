class AddStatusToBundleItemParts < ActiveRecord::Migration
  def change
    add_column :bundle_item_parts, :status, :integer, :default => 1, :after => :bundle_item_id
  end
end
