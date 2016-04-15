class AddAttachmentImageToDeliveries < ActiveRecord::Migration
  def self.up
    change_table :deliveries do |t|
      t.attachment :image
    end
  end

  def self.down
    remove_attachment :deliveries, :image
  end
end
