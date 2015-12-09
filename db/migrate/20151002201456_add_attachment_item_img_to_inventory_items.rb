class AddAttachmentItemImgToInventoryItems < ActiveRecord::Migration
  def self.up
    change_table :inventory_items do |t|
      t.attachment :item_img
    end
  end

  def self.down
    remove_attachment :inventory_items, :item_img
  end
end
